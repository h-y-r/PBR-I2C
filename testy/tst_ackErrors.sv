`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL testbench.dv_i2c.tr_mailbox
`define RAND testbench.i2c_cfg
`define TRANS testbench.test_tr

import transaction_class::*;

module tst_ackErrors;

bit RW_BIT;
bit prev_sda;
bit nackInMid;
bit ackAtEnd;

realtime nackInMid_time;
realtime ackAtEnd_time;

event assert_chk_nackInMid;
event assert_chk_ackAtEnd;

parameter int NUM_TRANSACTIONS = 20;

initial begin
    Transaction tr;

    `RAND = new();
    #100ns;

    if (!`RAND.randomize()) begin
    	$error("blad");
	end

    `DRIVER.HIGH_PERIOD_SCL   = `RAND.high_period;
    `DRIVER.LOW_PERIOD_SCL    = `RAND.low_period;
    `DRIVER.DATA_SETUP_TIME   = `RAND.setup_time;
    `DRIVER.RAND_STOP_BIT     = `RAND.rand_bit;
    `DRIVER.START_SETUP_TIME  = `RAND.start_setup_time;
    `DRIVER.START_HOLD_TIME   = `RAND.start_hold_time;
    `DRIVER.STOP_SETUP_TIME   = `RAND.stop_setup_time;
    `DRIVER.DATA_HOLD_TIME    = `DRIVER.LOW_PERIOD_SCL - `DRIVER.DATA_SETUP_TIME;

    `DRIVER.burstReadError(7'b0010000, 2);

    wait (`DRIVER.phase == M_ACK_DATA);
    prev_sda = testbench.SDA;
    wait (testbench.SCL == 1);	
    nackInMid = (prev_sda == testbench.SDA);
    nackInMid_time = $realtime();
    -> assert_chk_nackInMid;

    #10ns;

    wait (`DRIVER.phase == M_ACK_DATA);
    prev_sda = testbench.SDA;
    wait (testbench.SCL == 1);	
    ackAtEnd = (prev_sda == testbench.SDA);
    ackAtEnd_time = $realtime();
    -> assert_chk_ackAtEnd;

    #100ns;

    #10ns;
    $finish();
end

always @(assert_chk_nackInMid) begin
    chk_nackInMid : assert(nackInMid)
        $display("chk_nackInMid PASSED");
        else $error("chk_nackInMid FAILED at time %0t", nackInMid_time);
end

always @(assert_chk_ackAtEnd) begin
    chk_ackAtEnd : assert(ackAtEnd)
        $display("chk_ackAtEnd PASSED");
        else $error("chk_ackAtEnd FAILED at time %0t", ackAtEnd_time);
end

endmodule
