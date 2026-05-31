`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL testbench.dv_i2c.tr_mailbox
`define RAND testbench.i2c_cfg
`define TRANS testbench.test_tr

import transaction_class::*;
class data;
    rand logic [7:0] byte1;
    rand logic [7:0] byte2;
    rand logic [7:0] byte3;
    rand logic [7:0] byte4;
    rand logic [7:0] byte5;
    rand logic [7:0] byte6;
    rand logic [7:0] byte7;
    rand logic [7:0] byte8;
    rand logic [7:0] byte9;
    rand logic [7:0] byte10;
    rand logic [7:0] byte11;
    rand logic [7:0] byte12;
    rand logic [7:0] byte13;
    rand logic [7:0] byte14;
    rand logic [7:0] byte15;
    rand logic [7:0] byte16;
endclass

module tst_writeTransaction;
int j = 0;
int k = 0;
// Deklaracje zmiennych
bit OVERFLOW;
bit FULLBUFF;
bit OUTOFRANGE;
bit MULTIPLEWRITE;

event assert_chk_sameAdress;
event assert_chk_overflow;
event assert_chk_dataFullBuff;
event assert_chk_outOfRange;

parameter int NUM_TRANSACTIONS = 8;
parameter int NUM_RUNS = 8;

bit [7:0] dataOut [2*NUM_TRANSACTIONS-1:0];
bit [7:0] dataIn  [2*NUM_TRANSACTIONS-1:0];


property ACK_AFTER_DATA;
    @(posedge testbench.SCL)
    (`DRIVER.phase == M_DATA_TX && (`DRIVER.bit_idx == 0))
    |->
    (`DRIVER.ack_got == 1'b1);
endproperty 

initial begin
    Transaction tr;
    Transaction tr2;
    Transaction tr3;
    data random_bytes = new();

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

    for (int l = 0; l <= NUM_RUNS; l++) begin   
        if (!random_bytes.randomize()) begin
            $error("blad - randomizacja danych");
        end

        dataOut[0] = random_bytes.byte1;
        dataOut[1] = random_bytes.byte2;
        dataOut[2] = random_bytes.byte3;
        dataOut[3] = random_bytes.byte4;
        dataOut[4] = random_bytes.byte5;
        dataOut[5] = random_bytes.byte6;
        dataOut[6] = random_bytes.byte7;
        dataOut[7] = random_bytes.byte8;
        dataOut[8] = random_bytes.byte9;
        dataOut[9] = random_bytes.byte10;
        dataOut[10] = random_bytes.byte11;
        dataOut[11] = random_bytes.byte12;
        dataOut[12] = random_bytes.byte13;
        dataOut[13] = random_bytes.byte14;
        dataOut[14] = random_bytes.byte15;
        dataOut[15] = random_bytes.byte16;

        //TEST ZAPISU PELNEGO BUFORA I OVEFLOW
        tr = new(
            .addr(7'b0010000), 
            .rwSet(0), 
            .data_to_send({7'h00, random_bytes.byte1, random_bytes.byte2, random_bytes.byte3, random_bytes.byte4, 
                           random_bytes.byte5, random_bytes.byte6, random_bytes.byte7, random_bytes.byte8, 
                           random_bytes.byte9, random_bytes.byte10, random_bytes.byte11, random_bytes.byte12, 
                           random_bytes.byte13, random_bytes.byte14, random_bytes.byte15, random_bytes.byte16})
        );
        
        `MAIL.put(tr);
        wait (`DRIVER.phase == M_DONE);

        tr2 = new(
            .addr(7'b0010000),
            .rwSet(0),
            .data_to_send({7'h00})
        );

        `MAIL.put(tr2);

        tr3 = new(
            .addr(7'b0010000),
            .rwSet(1),
            .r_len(16)
        );

        `MAIL.put(tr3);

        wait (`DRIVER.phase == M_DATA_RX);
        for (int k = 0; k <= NUM_TRANSACTIONS*2-1; k++) begin
            wait (`DRIVER.phase == M_ACK_DATA);
            dataIn[k] = `DRIVER.data_got;
            #20us;
        end

        $display("data sent = %p", dataOut);
        $display("data got = %p", dataIn);

        FULLBUFF = (dataOut[3:0] == dataIn[3:0]);
        -> assert_chk_dataFullBuff;
        #1us;

        OVERFLOW = (dataOut[15:12] == dataIn[3:0]);
        -> assert_chk_overflow;
        #1us;
        //TEST ZAPISU PELNEGO BUFORA I OVEFLOW

        //TEST POWYZEJ BUFORA - powinien byc NACK, NIEISTNIEJACY ADRES I OUT OF RANGE
        if (!random_bytes.randomize()) begin
            $error("blad - randomizacja danych");
        end

        dataOut[0] = random_bytes.byte1;
        dataOut[1] = random_bytes.byte2;
        dataOut[2] = random_bytes.byte3;
        dataOut[3] = random_bytes.byte4;
        dataOut[4] = random_bytes.byte5;
        dataOut[5] = random_bytes.byte6;
        dataOut[6] = random_bytes.byte7;
        dataOut[7] = random_bytes.byte8;
        dataOut[8] = random_bytes.byte9;
        dataOut[9] = random_bytes.byte10;
        dataOut[10] = random_bytes.byte11;
        dataOut[11] = random_bytes.byte12;
        dataOut[12] = random_bytes.byte13;
        dataOut[13] = random_bytes.byte14;
        dataOut[14] = random_bytes.byte15;
        dataOut[15] = random_bytes.byte16;

        tr = new(
            .addr(7'b0010000), 
            .rwSet(0), 
            .data_to_send({7'h16, random_bytes.byte1, random_bytes.byte2, random_bytes.byte3, random_bytes.byte4, 
                           random_bytes.byte5, random_bytes.byte6, random_bytes.byte7, random_bytes.byte8, 
                           random_bytes.byte9, random_bytes.byte10, random_bytes.byte11, random_bytes.byte12, 
                           random_bytes.byte13, random_bytes.byte14, random_bytes.byte15, random_bytes.byte16})
        );
        
        `MAIL.put(tr);

        wait (`DRIVER.phase == M_DONE);

        tr2 = new(
            .addr(7'b0010000),
            .rwSet(0),
            .data_to_send({7'h16})
        );

        `MAIL.put(tr2);
        wait (`DRIVER.phase == M_ACK_DATA);
        OUTOFRANGE = (testbench.SDA == 1);
        -> assert_chk_outOfRange;
        //TEST POWYZEJ BUFORA - powinien byc NACK, NIEISTNIEJACY ADRES I OUT OF RANGE
        #1us;
    end
    $finish(0);
end


always @(assert_chk_dataFullBuff) begin
    chk_dataFullBuff: assert(FULLBUFF)
        $display("chk_dataFullBuff PASSED");
        else $error("chk_dataFullBuff: FAILED");
end

always @(assert_chk_overflow) begin
    chk_overflow : assert(OVERFLOW)
        $display("chk_overflow PASSED");
        else $error("chk_overflow FAILED");
end

always @(assert_chk_outOfRange) begin
    chk_outOfRange : assert(OUTOFRANGE)
        $display("chk_outOfRange PASSED");
        else $error("chk_outOfRange FAILED");
end

endmodule