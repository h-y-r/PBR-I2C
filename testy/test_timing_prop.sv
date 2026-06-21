`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL   testbench.dv_i2c.tr_mailbox
`define RAND   testbench.i2c_cfg
`define TRANS  testbench.test_tr

import transaction_class::*;
import i2c_timing_types_pkg::*;

module basic_test;

timeunit 1ns;
timeprecision 1ps;
int NUM_TRANSACTIONS = testbench.NUM_TRANSACTIONS;

i2c_timing_cfg_t timing_cfg;

realtime t_last_sda_change;
realtime t_last_scl_fall;
realtime t_last_scl_fall_previous;
bit      scl_has_history;

always @(testbench.SDA) begin
    t_last_sda_change = $realtime;
end

always @(negedge testbench.SCL) begin
    t_last_scl_fall_previous = t_last_scl_fall;
    t_last_scl_fall = $realtime;
    scl_has_history = 1;
end




initial begin
    Transaction tr;
    Transaction tr2;
    string mode_arg;
    //timing_cfg = get_cfg(MODE_STD);

    //wywolanie xrun ... +I2C_MODE=STD,FAST,FAST_PLUS
    `RAND = new();

    if (!$value$plusargs("I2C_MODE=%s", mode_arg))

        mode_arg = "STD";

    case (mode_arg)

        "STD": begin

            timing_cfg = get_cfg(MODE_STD);

            `RAND.mode = MODE_STD;

        end

        "FAST": begin

            timing_cfg = get_cfg(MODE_FAST);

            `RAND.mode = MODE_FAST;

        end

        "FAST_PLUS": begin

            timing_cfg = get_cfg(MODE_FMP);

            `RAND.mode = MODE_FMP;

        end

        default:

            $fatal(1, "Unsupported I2C_MODE=%s", mode_arg);

    endcase
    //`RAND = new();
    for(int i = 1; i<=NUM_TRANSACTIONS;i++)begin
        if (!`RAND.randomize())
            $error("Randomization failed");

        `DRIVER.HIGH_PERIOD_SCL  = `RAND.high_period;
        `DRIVER.LOW_PERIOD_SCL   = `RAND.low_period;
        `DRIVER.DATA_SETUP_TIME  = `RAND.setup_time;
        `DRIVER.START_SETUP_TIME = `RAND.start_setup_time;
        `DRIVER.START_HOLD_TIME  = `RAND.start_hold_time;
        `DRIVER.STOP_SETUP_TIME  = `RAND.stop_setup_time;
        //`DRIVER.DATA_HOLD_TIME   = `DRIVER.LOW_PERIOD_SCL - `DRIVER.DATA_SETUP_TIME;
        `DRIVER.DATA_HOLD_TIME   = `RAND.low_period - `RAND.setup_time;

        $display("\n==================================================");
        $display("[I2C_TEST_CFG] WYBRANY TRYB: %s", mode_arg);
        $display("--------------------------------------------------");
        $display("Wylosowane wartosci czasowe przekazane do Drivera:");
        $display(" -> HIGH_PERIOD_SCL  = %0f ns", `RAND.high_period);
        $display(" -> LOW_PERIOD_SCL   = %0f ns", `RAND.low_period);
        $display(" -> DATA_SETUP_TIME  = %0f ns", `RAND.setup_time);
        $display(" -> DATA_HOLD_TIME   = %0f ns", (`RAND.low_period - `RAND.setup_time));
        $display(" -> START_SETUP_TIME = %0f ns", `RAND.start_setup_time);
        $display(" -> START_HOLD_TIME  = %0f ns", `RAND.start_hold_time);
        $display(" -> STOP_SETUP_TIME  = %0f ns", `RAND.stop_setup_time);
        $display("==================================================\n");

        #100ns;

        tr = new(
            .addr(testbench.ADDR),
            .rwSet(0),
            .data_to_send({8'b10101010, 8'b11100011})
        );

        tr2 = new(
            .addr(testbench.ADDR),
            .rwSet(0),
            .data_to_send({8'b10101010, 8'b11100011})
        );

        `MAIL.put(tr);

        #20us;

        `MAIL.put(tr2);

        #500us;
    end
    $finish;
end




property P_SCL_PERIOD;
    @(negedge testbench.SCL)
    (`DRIVER.phase != M_IDLE && scl_has_history) |-> (($realtime - t_last_scl_fall_previous) >= timing_cfg.T_SCL_MIN);
endproperty

chk_SCLPeriod: assert property (P_SCL_PERIOD)
    $display("chk_SCLPeriod PASSED");
else
    $error("TIMING VIOLATION: SCL period too short, expected >= %0t",
           timing_cfg.T_SCL_MIN);

property P_START_HOLD;
    realtime t_start;

    @(negedge testbench.SDA)
    //disable iff (`DRIVER.phase != M_START)
    (testbench.SCL == 1 && (`DRIVER.phase == M_START || `DRIVER.phase == M_ADDR || `DRIVER.phase == M_IDLE), t_start = $realtime)
    |-> @(negedge testbench.SCL)
        (($realtime - t_start) >= timing_cfg.T_HD_STA_MIN);
endproperty

chk_startHoldTime: assert property (P_START_HOLD)
    $display("chk_startHoldTime PASSED");
else
    $error("TIMING VIOLATION: START hold time too short, expected >= %0t",
           timing_cfg.T_HD_STA_MIN);


property P_REPEATED_START_SETUP;
    realtime t_scl_rise;

    @(posedge testbench.SCL)
    disable iff (`DRIVER.phase != M_START)
    (`DRIVER.phase == M_START, t_scl_rise = $realtime)
    |-> @(negedge testbench.SDA)
        (testbench.SCL == 1 &&
        (($realtime - t_scl_rise) >= timing_cfg.T_SU_STA_MIN));
endproperty

chk_repeatedStartSetupTime: assert property (P_REPEATED_START_SETUP)
    $display("chk_repeatedStartSetupTime PASSED");
else
    $error("TIMING VIOLATION: repeated START setup time too short, expected >= %0t",
           timing_cfg.T_SU_STA_MIN);


property P_STOP_SETUP;
    realtime t_scl_rise;

    @(posedge testbench.SCL)
    disable iff (`DRIVER.phase != M_STOP)
    (`DRIVER.phase == M_STOP, t_scl_rise = $realtime)
    |-> @(posedge testbench.SDA)
        (testbench.SCL == 1 &&
        (($realtime - t_scl_rise) >= timing_cfg.T_SU_STO_MIN));
endproperty

chk_stopSetUpTime: assert property (P_STOP_SETUP)
    $display("chk_stopSetUpTime PASSED");
else
    $error("TIMING VIOLATION: STOP setup time too short, expected >= %0t",
           timing_cfg.T_SU_STO_MIN);



property P_STOP_START_FREE_TIME;
    realtime t_stop;

   
    @(posedge testbench.SDA)
    (testbench.SCL == 1, t_stop = $realtime)
    

    |-> @(negedge testbench.SDA)
        (testbench.SCL == 1) |-> (($realtime - t_stop) >= timing_cfg.T_BUF_MIN);
endproperty

chk_stopStartFreeTime: assert property (P_STOP_START_FREE_TIME)
    $display("chk_stopStartFreeTime PASSED");
else
    $error("TIMING VIOLATION: bus free time STOP-to-START too short, expected >= %0t",
           timing_cfg.T_BUF_MIN);



property P_DATA_SETUP;
    @(posedge testbench.SCL)
    (`DRIVER.phase == M_DATA_RX || `DRIVER.phase == M_DATA_TX)
    |->
    (($realtime - t_last_sda_change) >= timing_cfg.T_SU_DAT_MIN);
endproperty

chk_dataSetUpTime: assert property (P_DATA_SETUP)
    $display("chk_dataSetUpTime PASSED");
else
    $error("TIMING VIOLATION: DATA setup time too short, expected >= %0t",
           timing_cfg.T_SU_DAT_MIN);




property P_DATA_HOLD;
    @(testbench.SDA)
    (`DRIVER.phase == M_DATA_RX || `DRIVER.phase == M_DATA_TX)
    |->
    (($realtime - t_last_scl_fall) >= timing_cfg.T_HD_DAT_MIN);
endproperty

chk_dataHoldTime: assert property (P_DATA_HOLD)
    $display("chk_dataHoldTime PASSED");
else
    $error("TIMING VIOLATION: DATA hold time too short, expected >= %0t",
           timing_cfg.T_HD_DAT_MIN);


property P_DATA_STABLE_WHILE_SCL_HIGH;
    @(testbench.SDA)
    !((`DRIVER.phase == M_DATA_RX || `DRIVER.phase == M_DATA_TX) &&
      testbench.SCL == 1);
endproperty

chk_dataValidTime: assert property (P_DATA_STABLE_WHILE_SCL_HIGH)
    $display("chk_dataValidTime PASSED");
else
    $error("TIMING VIOLATION: SDA changed while SCL high during DATA phase");


endmodule