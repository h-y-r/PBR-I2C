`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL testbench.dv_i2c.tr_mailbox
`define RAND testbench.i2c_cfg
`define TRANS testbench.test_tr
`define TARGET_BITS testbench.tg_i2c.data_send //ostatnie do zmieniania, latwiej bedzie dla roznych targetow z definicja

import transaction_class::*;

module test;

// Deklaracje zmiennych
bit signal;

bit EXPECTED_START_STOP;
bit RESET_AFTER_START;
bit CLOCK_STRETCH;
bit START_NO_ACK;
bit ADRESS_10BIT;
bit scl_mismatch_flag = 0;

event assert_chk_startStopCondition;
event assert_chk_resetAfterStart;
event assert_chk_stopImmediatelyAfterStop;
event assert_chk_startNoAck;

realtime time1;
realtime time2;


property STOP_IMMEDIATELY_AFTER_START;
	@(posedge testbench.clk)
	(`DRIVER.phase == M_DONE) ##[1:235] (`DRIVER.phase == M_START) |=> (`TARGET.state == 1);
endproperty	


initial begin
	Transaction tr1;
	Transaction tr2;
	`RAND = new();
	if (!`RAND.randomize()) begin
	$error("blad");
	end

	`DRIVER.HIGH_PERIOD_SCL = `RAND.high_period;
	`DRIVER.LOW_PERIOD_SCL  = `RAND.low_period;
	`DRIVER.DATA_SETUP_TIME = `RAND.setup_time;
	`DRIVER.RAND_STOP_BIT = `RAND.rand_bit;
	`DRIVER.START_SETUP_TIME = `RAND.start_setup_time;
	`DRIVER.START_HOLD_TIME = `RAND.start_hold_time;
	`DRIVER.STOP_SETUP_TIME = `RAND.stop_setup_time;
	`DRIVER.DATA_HOLD_TIME = `DRIVER.LOW_PERIOD_SCL - `DRIVER.DATA_SETUP_TIME;	
	#100ns;
		
	tr1 = new(
        .addr(7'b0000111), 
        .rwSet(0), 
        .data_to_send({8'b10101010})
    );

	tr2 = new(
        .addr(7'b0000111), 
        .rwSet(0), 
        .data_to_send({8'b10101010})
    );
	
	`MAIL.put(tr1);
	
	wait (`DRIVER.phase == M_START);
	
	START_NO_ACK = ((`DRIVER.phase == M_START) && (`TARGET.SDA_tx != 1'b0));
	-> assert_chk_startNoAck;
	
	wait (`DRIVER.phase == M_DONE);
	`MAIL.put(tr2);
	
	wait (`DRIVER.phase == M_DONE);
	@(negedge testbench.SDA) time1 = $realtime();
	@(negedge testbench.SCL) time2 = $realtime();
	
	EXPECTED_START_STOP = ((`DRIVER.phase == M_START) && (((time2 - time1) < 4us) && ((time2 - time1) > 4ns)));
	-> assert_chk_startStopCondition;
	
	wait(testbench.SDA == 1'b0);
	RESET_AFTER_START = ((`DRIVER.phase == M_START) && (testbench.SDA == 1'b0) && `TARGET.state == 0);
	-> assert_chk_resetAfterStart;
	
	`DRIVER.BUFF_TIME = 0;
	
	wait (`DRIVER.phase == M_DONE);
	`DRIVER.sendStart();
	
	#1000us;
	$finish();
end

chk_stopImmediatelyAfterStart : assert property(STOP_IMMEDIATELY_AFTER_START) $display("chk_stopImmediatelyAfterStop PASSED!");
		else $error("chk_stopImmediatelyAfterStop FAILED!");	
		
always @(assert_chk_startNoAck) begin					
	chk_startNoAck	: assert(START_NO_ACK) $display("chk_startNoAck PASSED!");
		else $error("chk_startNoAck FAILED!");
end		

always @(assert_chk_startStopCondition) begin
	chk_startStopCondition : assert(EXPECTED_START_STOP) $display("chk_startStopCondition PASSED!");
		else $error("chk_startStopCondition FAILED!");
end	
				
always @(assert_chk_resetAfterStart) begin					
	chk_resetAfterStart	: assert(RESET_AFTER_START) $display("chk_resetAfterStart PASSED!");
		else $error("chk_resetAfterStart FAILED!");
end

					
always @(posedge testbench.clk) begin
    if (`DRIVER.SCL_ctrl !== testbench.SCL & !scl_mismatch_flag) begin
        scl_mismatch_flag = 1;
        $display("SCL mismatch at time %0t", $realtime);
    end
end

final begin
    chk_sclMismatch : assert(scl_mismatch_flag == 0) $display("chk_scl_only_master PASSED!");
        else $error("chk_scl_only_master FAILED! SCL was driven not by master!");
end

endmodule
