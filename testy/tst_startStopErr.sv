`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL testbench.dv_i2c.tr_mailbox
`define RAND testbench.i2c_cfg
`define TRANS testbench.test_tr
`define TARGET_BITS testbench.tg_i2c.data_send 

import transaction_class::*;

module basic_test;

class rand_bit;
    rand int stopbit;

    constraint rand_bit_const{
        stopbit inside {[0:7]};
    }
endclass

class rand_byte;
    rand logic[7:0] byte1;
endclass

bit RAND_STOP_WRITE_EN = 1'b0;
bit DOUBLE_START_EN = 1'b0;
bit RAND_START_WRITE_EN = 1'b0;
bit STOP_START_EN = 1'b0;
bit FALSE_START_EN = 1'b0;
bit FALSE_STOP_EN = 1'b0;
bit HOLD_STOP_EN = 1'b0;
bit REPEATED_START_NO_STOP_EN = 1'b0;

property RAND_STOP_WRITE;
    @(posedge testbench.SCL)
    (`DRIVER.phase == M_ADDR) && (`DRIVER.bit_idx == -1) && (RAND_STOP_WRITE_EN)
    |->
    (`DRIVER.ack_got == 1'b1)
endproperty

property RAND_START_WRITE;
    @(posedge testbench.SCL)
    (`DRIVER.phase == M_ACK_ADDR) && (`DRIVER.bit_idx == `DRIVER.BIT_ACK) && (RAND_START_WRITE_EN)
    |->
    (`DRIVER.ack_got == 1'b1)
endproperty


property DOUBLE_START;
    @(posedge testbench.SCL)
    (`DRIVER.phase == M_ACK_ADDR) && (`DRIVER.bit_idx == `DRIVER.BIT_ACK) && (DOUBLE_START_EN)
    |->
    (`DRIVER.ack_got == 1'b1)
endproperty

property STOP_START;
    @(posedge testbench.SCL)
    (`DRIVER.phase == M_ACK_ADDR) && (`DRIVER.bit_idx == `DRIVER.BIT_ACK) && (STOP_START_EN)
    |->
    (`DRIVER.ack_got == 1'b1)
endproperty


property FALSE_START;
    @(posedge testbench.SCL)
    (`DRIVER.phase == M_ACK_ADDR) && (`DRIVER.bit_idx == `DRIVER.BIT_ACK) && (FALSE_START_EN)
    |->
    (`DRIVER.ack_got == 1'b1)
endproperty


property FALSE_STOP;
    @(posedge testbench.SCL)
    (`DRIVER.phase == M_ACK_ADDR) && (`DRIVER.bit_idx == `DRIVER.BIT_ACK) && (FALSE_STOP_EN)
    |->
    (`DRIVER.ack_got == 1'b1)
endproperty

property HOLD_STOP;
    @(posedge testbench.SCL)
    (`DRIVER.phase == M_ACK_ADDR) && (`DRIVER.bit_idx == `DRIVER.BIT_ACK) && (HOLD_STOP_EN)
    |->
    (`DRIVER.ack_got == 1'b1)
endproperty

property REPEATED_START_NO_STOP;
    @(posedge testbench.SCL)
    (`DRIVER.phase == M_ACK_ADDR) && (`DRIVER.bit_idx == `DRIVER.BIT_ACK) && (REPEATED_START_NO_STOP_EN)
    |->
    (`DRIVER.ack_got == 1'b1)
endproperty


int NUM_TRANSACTIONS = testbench.NUM_TRANSACTIONS;

initial begin
    rand_bit stopbit;
    rand_byte data;
    Transaction tr;
    `RAND = new();
    stopbit = new();
    data = new();
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


    for(int i = 1; i<=NUM_TRANSACTIONS; i++)begin
        if(!stopbit.randomize()) $error("chk_randStop - stop bit randomization failed");
        if(!data.randomize()) $error("chk_randStop - data randomization failed");

        `DRIVER.writeRandomStop(7'b0010000, data.byte1, stopbit.stopbit);
        //wait(`DRIVER.phase == M_START);
        //wait(`DRIVER.phase == M_DONE);
        tr = new(
            .addr(7'b0010000),
            .rwSet(0),
            .data_to_send({8'd0})
        );

        
        `MAIL.put(tr);
        wait(`DRIVER.phase == M_START);
        wait(`DRIVER.phase == M_DONE);

        tr = new(
            .addr(7'b0010000),
            .rwSet(1),
            .r_len(1)
        );


        RAND_STOP_WRITE_EN = 1'b1;
        `MAIL.put(tr);
        wait(`DRIVER.phase == M_START);
        wait(`DRIVER.phase == M_DONE);
        RAND_STOP_WRITE_EN = 1'b0;


    end

    // DOUBLE_START_EN = 1'b1;

    // for(int i = 1; i<=NUM_TRANSACTIONS; i++)begin

    //     `DRIVER.readDoubleStartErr(7'b0010000);

    //     //wait(`DRIVER.phase == M_START);
    //     //wait(`DRIVER.phase == M_DONE);
        

    // end

    // DOUBLE_START_EN = 1'b0;

    for(int i = 1; i<=NUM_TRANSACTIONS; i++)begin
        if(!stopbit.randomize()) $error("chk_doubleStart - stop bit randomization failed");
        if(!data.randomize()) $error("chk_doubleStart - data randomization failed");

        `DRIVER.writeRandomStart(7'b0010000, data.byte1, stopbit.stopbit);
        //wait(`DRIVER.phase == M_START);
        //wait(`DRIVER.phase == M_DONE);
        tr = new(
            .addr(7'b0010000),
            .rwSet(0),
            .data_to_send({8'd0})
        );

        
        `MAIL.put(tr);
        wait(`DRIVER.phase == M_START);
        wait(`DRIVER.phase == M_DONE);

        tr = new(
            .addr(7'b0010000),
            .rwSet(1),
            .r_len(1)
        );


        RAND_START_WRITE_EN = 1'b1;
        `MAIL.put(tr);
        wait(`DRIVER.phase == M_START);
        wait(`DRIVER.phase == M_DONE);
        RAND_START_WRITE_EN = 1'b0;

    end

    
    for(int i = 1; i<=NUM_TRANSACTIONS; i++)begin
        tr = new(
            .addr(7'b0010000),
            .rwSet(0),
            .data_to_send({8'd0})
        );

        `MAIL.put(tr);

        wait(`DRIVER.phase == M_START);
        wait(`DRIVER.phase == M_DONE);
        STOP_START_EN = 1'b1;


        `DRIVER.stopStartReadErr(7'b0010000);
        STOP_START_EN = 1'b0;

        //wait(`DRIVER.phase == M_START);
        //wait(`DRIVER.phase == M_DONE);
        

    end



    for(int i = 1; i<=NUM_TRANSACTIONS; i++)begin
        if(!stopbit.randomize()) $error("chk_falseStart - stop bit randomization failed");
        if(!data.randomize()) $error("chk_falseStart - data randomization failed");

        `DRIVER.falseStart(7'b0010000, data.byte1, stopbit.stopbit);
        //wait(`DRIVER.phase == M_START);
        //wait(`DRIVER.phase == M_DONE);
        tr = new(
            .addr(7'b0010000),
            .rwSet(0),
            .data_to_send({8'd0})
        );

        
        `MAIL.put(tr);
        wait(`DRIVER.phase == M_START);
        wait(`DRIVER.phase == M_DONE);

        tr = new(
            .addr(7'b0010000),
            .rwSet(1),
            .r_len(1)
        );


        FALSE_START_EN = 1'b1;
        `MAIL.put(tr);
        wait(`DRIVER.phase == M_START);
        wait(`DRIVER.phase == M_DONE);
        FALSE_START_EN = 1'b0;

    end

    for(int i = 1; i<=NUM_TRANSACTIONS; i++)begin
        if(!stopbit.randomize()) $error("chk_falseStop - stop bit randomization failed");
        if(!data.randomize()) $error("chk_falseStop - data randomization failed");

        `DRIVER.falseStop(7'b0010000, data.byte1, stopbit.stopbit);
        //wait(`DRIVER.phase == M_START);
        //wait(`DRIVER.phase == M_DONE);
        tr = new(
            .addr(7'b0010000),
            .rwSet(0),
            .data_to_send({8'd0})
        );

        
        `MAIL.put(tr);
        wait(`DRIVER.phase == M_START);
        wait(`DRIVER.phase == M_DONE);

        tr = new(
            .addr(7'b0010000),
            .rwSet(1),
            .r_len(1)
        );


        FALSE_STOP_EN = 1'b1;
        `MAIL.put(tr);
        wait(`DRIVER.phase == M_START);
        wait(`DRIVER.phase == M_DONE);
        FALSE_STOP_EN = 1'b0;

    end


    for(int i = 1; i<=NUM_TRANSACTIONS; i++)begin
        if(!`RAND.randomize()) $error("chk_holdStop - stop bit randomization failed");

        `DRIVER.STOP_WAIT_TIME_ERR = `RAND.stop_wait_time_err;

        `DRIVER.stopHoldErr(7'b0010000);
        //wait(`DRIVER.phase == M_START);
        //wait(`DRIVER.phase == M_DONE);
        tr = new(
            .addr(7'b0010000),
            .rwSet(0),
            .data_to_send({8'd0})
        );

        
        `MAIL.put(tr);
        wait(`DRIVER.phase == M_START);
        wait(`DRIVER.phase == M_DONE);

        tr = new(
            .addr(7'b0010000),
            .rwSet(1),
            .r_len(1)
        );


        HOLD_STOP_EN = 1'b1;
        `MAIL.put(tr);
        wait(`DRIVER.phase == M_START);
        wait(`DRIVER.phase == M_DONE);
        HOLD_STOP_EN = 1'b0;

    end


    for(int i = 1; i<=NUM_TRANSACTIONS; i++)begin
        if(!data.randomize()) $error("chk_repeatedStartNoStop - data randomization failed");


        `DRIVER.repeatedStartNoStopErr(7'b0010000, data.byte1);
        //wait(`DRIVER.phase == M_START);
        //wait(`DRIVER.phase == M_DONE);
        tr = new(
            .addr(7'b0010000),
            .rwSet(0),
            .data_to_send({8'd0})
        );

        
        `MAIL.put(tr);
        wait(`DRIVER.phase == M_START);
        wait(`DRIVER.phase == M_DONE);

        tr = new(
            .addr(7'b0010000),
            .rwSet(1),
            .r_len(1)
        );


        REPEATED_START_NO_STOP_EN = 1'b1;
        `MAIL.put(tr);
        wait(`DRIVER.phase == M_START);
        wait(`DRIVER.phase == M_DONE);
        REPEATED_START_NO_STOP_EN = 1'b0;

    end

    $finish();
end

chk_randStop:               assert property (RAND_STOP_WRITE) $display("chk_randStop PASSED!");
                            else $error("chk_randStop FAILED!");

chk_doubleStart:            assert property (DOUBLE_START) $display("chk_doubleStart PASSED!");
                            else $error("chk_doubleStart FAILED!");

chk_randStart:              assert property (RAND_START_WRITE) $display("chk_randStart PASSED!");
                            else $error("chk_randStart FAILED!");

chk_stopStart:              assert property (STOP_START) $display("chk_stopStart PASSED!");
                            else $error("chk_stopStart FAILED!");

chk_falseStart:             assert property (FALSE_START) $display("chk_falseStart PASSED!");
                            else $error("chk_falseStart FAILED!");

chk_falseStop:              assert property (FALSE_STOP) $display("chk_falseStop PASSED!");
                            else $error("chk_falseStop FAILED!");

chk_holdStop:               assert property (HOLD_STOP) $display("chk_holdStop PASSED!");
                            else $error("chk_holdStop FAILED!");

chk_repeatedStartNoStop:    assert property (REPEATED_START_NO_STOP) $display("chk_repeatedStartNoStop PASSED!");
                            else $error("chk_repeatedStartNoStop FAILED!");

endmodule