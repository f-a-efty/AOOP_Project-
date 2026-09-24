-- SQL Lab Deliverable: Stored Procedures & Transaction Control
USE greenify_db;

DELIMITER //

-- Transaction Stored Procedure: Fulfill Plastic Deposit & Credit Tokens
CREATE PROCEDURE sp_process_plastic_deposit(
    IN p_user_id BIGINT,
    IN p_booth_id BIGINT,
    IN p_session_id VARCHAR(64),
    IN p_weight_kg DECIMAL(8,3),
    OUT p_tokens_earned INT
)
proc_label: BEGIN
    DECLARE v_rate INT DEFAULT 100;
    DECLARE v_calculated_tokens INT;
    DECLARE v_booth_capacity DECIMAL(8,3);
    DECLARE v_current_weight DECIMAL(8,3);
    DECLARE v_new_weight DECIMAL(8,3);
    DECLARE v_new_status VARCHAR(30);

    -- Exit on error with rollback
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- 1. Check and calculate token reward (100 tokens per kg -> floor(grams / 10))
    SET v_calculated_tokens = FLOOR(p_weight_kg * v_rate);
    SET p_tokens_earned = v_calculated_tokens;

    -- 2. Lock booth row & check capacity
    SELECT capacity_kg, current_weight_kg INTO v_booth_capacity, v_current_weight
    FROM smart_booths
    WHERE booth_id = p_booth_id
    FOR UPDATE;

    SET v_new_weight = v_current_weight + p_weight_kg;
    IF v_new_weight > v_booth_capacity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Deposit exceeds booth maximum capacity constraint.';
    END IF;

    -- 3. Determine new booth status
    IF v_new_weight >= v_booth_capacity THEN
        SET v_new_status = 'Full';
    ELSEIF (v_new_weight / v_booth_capacity) >= 0.80 THEN
        SET v_new_status = 'Almost Full';
    ELSE
        SET v_new_status = 'Available';
    END IF;

    -- 4. Insert plastic deposit record
    INSERT INTO plastic_deposits (user_id, booth_id, session_id, plastic_weight_kg, plastic_type, tokens_earned, rate_snapshot)
    VALUES (p_user_id, p_booth_id, p_session_id, p_weight_kg, 'PET/Mix', v_calculated_tokens, v_rate);

    -- 5. Lock user row & credit wallet tokens
    UPDATE users
    SET total_tokens = total_tokens + v_calculated_tokens
    WHERE user_id = p_user_id;

    -- 6. Record transaction ledger entry
    INSERT INTO wallet_transactions (user_id, transaction_type, tokens_delta, cash_delta, balance_after_tokens, status)
    SELECT p_user_id, 'Deposit Credit', v_calculated_tokens, 0.00, total_tokens, 'Completed'
    FROM users WHERE user_id = p_user_id;

    -- 7. Update booth weight and status
    UPDATE smart_booths
    SET current_weight_kg = v_new_weight,
        booth_status = v_new_status
    WHERE booth_id = p_booth_id;

    -- 8. Complete session
    UPDATE deposit_sessions
    SET status = 'COMPLETED'
    WHERE session_id = p_session_id;

    COMMIT;
END //

DELIMITER ;
