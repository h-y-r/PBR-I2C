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

module basic_test;
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
int NUM_RUNS = testbench.NUM_TRANSACTIONS;

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


    for (k = 0; k <= NUM_RUNS; k++) begin    
        if (!random_bytes.randomize()) begin
            $error("blad - randomizacja danych");
        end

        dataOut[0] = random_bytes.byte1;
        dataOut[1] = random_bytes.byte2;
        dataOut[2] = random_bytes.byte3;
        dataOut[3] = random_bytes.byte4;
        dataOut[4] = random_bytes.byte5;
        dataOut[5] = random_bytes.byte6;

        //TEST ZAPISU PELNEGO BUFORA I OVEFLOW
        for (int j = 0; j <= 5; j++) begin
            tr = new(
                .addr(7'b0010000), 
                .rwSet(0), 
                .data_to_send({7'h01, dataOut[j]})
            );
            
            `MAIL.put(tr);
            #32us;
        end
        wait (`DRIVER.phase == M_DONE);

        tr2 = new(
            .addr(7'b0010000),
            .rwSet(0),
            .data_to_send({7'h01})
        );

        `MAIL.put(tr2);

        wait (`DRIVER.phase == M_DONE);

        tr3 = new(
            .addr(7'b0010000),
            .rwSet(1),
            .r_len(1)
        );

        `MAIL.put(tr3);

        wait (`DRIVER.phase == M_DATA_RX);
        wait (`DRIVER.phase == M_ACK_DATA);
        dataIn[0] = `DRIVER.data_got;
        #20us;

        wait (`DRIVER.phase == M_DONE);

        $display("data sent = %p", dataOut);
        $display("data got = %p", dataIn);

        MULTIPLEWRITE = (dataIn[0] == dataOut[5]);
        -> assert_chk_sameAdress;
        #1us;
    end

    //TEST KILKA RAZY ZAPIS POD TEN SAM ADRES
    $finish(0);
end

always @(assert_chk_sameAdress) begin
    chk_sameAdress: assert(MULTIPLEWRITE)
        $display("chk_sameAdress PASSED");
        else $error("chk_sameAdress: FAILED");
end

endmodule