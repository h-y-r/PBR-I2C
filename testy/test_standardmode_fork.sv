`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL   testbench.dv_i2c.tr_mailbox
`define RAND   testbench.i2c_cfg
`define TRANS  testbench.test_tr

import transaction_class::*;
import i2c_timing_types_pkg::*;

module test;

timeunit 1ns;
timeprecision 1ps;

i2c_timing_cfg_t timing_cfg;

real t_last_sda_change;



always @(testbench.SDA)
    t_last_sda_change = $realtime;

always @(posedge testbench.SCL)
    t_scl_rise = $realtime;

initial begin
    Transaction tr;
    Transaction tr2;

    timing_cfg = get_cfg(MODE_STD);

    `RAND = new();
    if (!`RAND.randomize())
        $error("Randomization failed");

    `DRIVER.HIGH_PERIOD_SCL  = `RAND.high_period;
    `DRIVER.LOW_PERIOD_SCL   = `RAND.low_period;
    `DRIVER.DATA_SETUP_TIME  = `RAND.setup_time;
    `DRIVER.START_SETUP_TIME = `RAND.start_setup_time;
    `DRIVER.START_HOLD_TIME  = `RAND.start_hold_time;
    `DRIVER.STOP_SETUP_TIME  = `RAND.stop_setup_time;
    `DRIVER.DATA_HOLD_TIME   = `DRIVER.LOW_PERIOD_SCL - `DRIVER.DATA_SETUP_TIME;

    #100ns;

    tr = new(
        .addr(7'b0000111),
        .rwSet(0),
        .data_to_send({8'b10101010, 8'b11100011})
    );

    tr2 = new(
        .addr(7'b0000111),
        .rwSet(0),
        .data_to_send({8'b10101010, 8'b11100011})
    );

    fork
    begin
        wait(`DRIVER.phase == M_START);
        repeat (2) check_start_hold_time();
    end

    begin
        wait(`DRIVER.phase == M_DATA_RX || `DRIVER.phase == M_DATA_TX);
        repeat (20) check_scl_timing();
    end

    begin
        wait(`DRIVER.phase == M_DATA_RX || `DRIVER.phase == M_DATA_TX);
        repeat (16) check_data_setup_time();
    end

    begin
        wait(`DRIVER.phase == M_DATA_RX || `DRIVER.phase == M_DATA_TX);
        repeat (16) check_data_hold_time();
    end

    begin
        wait(`DRIVER.phase == M_DATA_RX || `DRIVER.phase == M_DATA_TX);
        repeat (16) check_data_valid_time();
    end

    begin
        wait(`DRIVER.phase == M_STOP);
        repeat (2) check_stop_setup_time();
    end

    begin
        repeat (1) check_stop_start_free_time();
    end
    join_none

    `MAIL.put(tr);

    #20us;

    `MAIL.put(tr2);

    #50us;
    $finish;
end


task automatic check_scl_timing();
    real t1, t2;
    real period;
    real freq_hz;
    real max_freq_hz;

    @(negedge testbench.SCL);
    t1 = $realtime;

    @(negedge testbench.SCL);
    t2 = $realtime;

    period      = t2 - t1;
    freq_hz     = 1e9 / period;
    max_freq_hz = 1e9 / timing_cfg.T_SCL_MIN;

    chk_SCLPeriod: assert(period >= timing_cfg.T_SCL_MIN)
        $display("chk_SCLPeriod PASSED: period=%0t", period);
    else
        $error("chk_SCLPeriod FAILED: period=%0t expected>=%0t",
               period, timing_cfg.T_SCL_MIN);

    chk_SCLClockFreq: assert(freq_hz <= max_freq_hz)
        $display("chk_SCLClockFreq PASSED: freq=%0f Hz", freq_hz);
    else
        $error("chk_SCLClockFreq FAILED: freq=%0f Hz max=%0f Hz",
               freq_hz, max_freq_hz);
endtask

task automatic check_start_hold_time();

    real t_start, t_scl_fall;
    real delta;

    @(negedge testbench.SDA iff (testbench.SCL == 1));
    t_start = $realtime;

    @(negedge testbench.SCL);
    t_scl_fall = $realtime;
    delta = t_scl_fall - t_start;
    chk_startHoldTime: assert(delta >= timing_cfg.T_HD_STA_MIN)

        $display("chk_startHoldTime PASSED: hold=%0t", delta);

    else

        $error("chk_startHoldTime FAILED: hold=%0t expected>=%0t",

               delta, timing_cfg.T_HD_STA_MIN);

endtask

task automatic check_repeated_start_setup_time();

    real t_scl_rise_local;
    real t_start;
    real delta;
    @(posedge testbench.SCL);
    t_scl_rise_local = $realtime;
    @(negedge testbench.SDA iff (testbench.SCL == 1));
    t_start = $realtime;
    delta = t_start - t_scl_rise_local;
    chk_repeatedStartSetupTime: assert(delta >= timing_cfg.T_SU_STA_MIN)

        $display("chk_repeatedStartSetupTime PASSED: setup=%0t", delta);

    else

        $error("chk_repeatedStartSetupTime FAILED: setup=%0t expected>=%0t",

               delta, timing_cfg.T_SU_STA_MIN);

endtask

task automatic check_stop_setup_time();

    real t_scl_rise_local;
    real t_stop;
    real delta;

    @(posedge testbench.SCL);
    t_scl_rise_local = $realtime;

    @(posedge testbench.SDA iff (testbench.SCL == 1));
    t_stop = $realtime;
    delta = t_stop - t_scl_rise_local;

    chk_stopSetUpTime: assert(delta >= timing_cfg.T_SU_STO_MIN)

        $display("chk_stopSetUpTime PASSED: setup=%0t", delta);

    else

        $error("chk_stopSetUpTime FAILED: setup=%0t expected>=%0t",

               delta, timing_cfg.T_SU_STO_MIN);

endtask

task automatic check_stop_start_free_time();

    real t_stop;
    real t_start;
    real delta;

    @(posedge testbench.SDA iff (testbench.SCL == 1));
    t_stop = $realtime;

    @(negedge testbench.SDA iff (testbench.SCL == 1));
    t_start = $realtime;
    delta = t_start - t_stop;

    chk_stopStartFreeTime: assert(delta >= timing_cfg.T_BUF_MIN)

        $display("chk_stopStartFreeTime PASSED: tbuf=%0t", delta);

    else

        $error("chk_stopStartFreeTime FAILED: tbuf=%0t expected>=%0t",

               delta, timing_cfg.T_BUF_MIN);

endtask

task automatic check_data_setup_time();

    real delta;

    @(posedge testbench.SCL);
    delta = $realtime - t_last_sda_change;

    chk_dataSetupTime: assert(delta >= timing_cfg.T_SU_DAT_MIN)

        $display("chk_dataSetupTime PASSED: setup=%0t", delta);

    else

        $error("chk_dataSetupTime FAILED: setup=%0t expected>=%0t",

               delta, timing_cfg.T_SU_DAT_MIN);

endtask

task automatic check_data_hold_time();

    real t_scl_fall;
    real t_sda_change;
    real delta;

    @(negedge testbench.SCL);
    t_scl_fall = $realtime;

    @(testbench.SDA);
    t_sda_change = $realtime;
    delta = t_sda_change - t_scl_fall;

    chk_dataHoldTime: assert(delta >= timing_cfg.T_HD_DAT_MIN)

        $display("chk_dataHoldTime PASSED: hold=%0t", delta);

    else

        $error("chk_dataHoldTime FAILED: hold=%0t expected>=%0t",

               delta, timing_cfg.T_HD_DAT_MIN);

endtask

task automatic check_data_valid_time();

    logic sda_sampled;

    @(posedge testbench.SCL);
    sda_sampled = testbench.SDA;
    #(timing_cfg.T_DATA_VALID_GUARD);
    chk_dataValidTime: assert(testbench.SDA == sda_sampled)

        $display("chk_dataValidTime PASSED");

    else

        $error("chk_dataValidTime FAILED: SDA changed while SCL high");

endtask



endmodule




