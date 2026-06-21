package i2c_timing_types_pkg;

  timeunit 1ns;
  timeprecision 1ps;

  typedef struct {
    time T_SCL_MIN; //minimalny okres chk_SCLClockFreq ok
    time T_HD_STA_MIN; //start hold time chk_startHoldTime ok 
    time T_SU_STA_MIN; //setup start chk_repeatedStartSetupTime
    time T_SU_DAT_MIN; // setup data chk_dataHoldSetUpTime
    time T_HD_DAT_MIN; //hold data chk_dataValidTime
    time T_SU_STO_MIN; //setup stop chk_stopSetUpTime
    time T_BUF_MIN; // wolna magistrala miedzy stop start chk_stopStartFreeTime ok 
    time T_DATA_VALID_GUARD; // stabilne dane na scl 1 
  } i2c_timing_cfg_t;



  function automatic i2c_timing_cfg_t get_std_mode_cfg();
    i2c_timing_cfg_t cfg;

    cfg.T_SCL_MIN        = 10_000ns; // do poprawy

    cfg.T_HD_STA_MIN     = 4_000ns;
    cfg.T_SU_STA_MIN     = 4_700ns;

    cfg.T_SU_DAT_MIN     = 250ns;
    cfg.T_HD_DAT_MIN     = 0ns;

    cfg.T_SU_STO_MIN     = 4_000ns;
    cfg.T_BUF_MIN        = 4_700ns;

    cfg.T_DATA_VALID_GUARD = 0ns;

    return cfg;
  endfunction

  function automatic i2c_timing_cfg_t get_fast_mode_cfg();
    i2c_timing_cfg_t cfg;
    cfg.T_SCL_MIN        = 2_500ns;

    cfg.T_HD_STA_MIN     = 600ns;
    cfg.T_SU_STA_MIN     = 600ns;

    cfg.T_SU_DAT_MIN     = 100ns;
    cfg.T_HD_DAT_MIN     = 0ns;

    cfg.T_SU_STO_MIN     = 600ns;
    cfg.T_BUF_MIN        = 1_300ns;

    cfg.T_DATA_VALID_GUARD = 0ns;

    return cfg;
  endfunction

  function automatic i2c_timing_cfg_t get_fast_mode_plus_cfg();
    i2c_timing_cfg_t cfg;

    cfg.T_SCL_MIN        = 1_000ns;

    cfg.T_HD_STA_MIN     = 260ns;
    cfg.T_SU_STA_MIN     = 260ns;

    cfg.T_SU_DAT_MIN     = 50ns;
    cfg.T_HD_DAT_MIN     = 0ns;

    cfg.T_SU_STO_MIN     = 260ns;
    cfg.T_BUF_MIN        = 500ns;

    cfg.T_DATA_VALID_GUARD = 0ns;

    return cfg;
  endfunction

  function automatic i2c_timing_cfg_t get_high_speed_cfg();
    i2c_timing_cfg_t cfg;

    cfg.T_SCL_MIN        = 294_118ps;  

    cfg.T_HD_STA_MIN     = 160ns;
    cfg.T_SU_STA_MIN     = 160ns;

    cfg.T_SU_DAT_MIN     = 10ns;
    cfg.T_HD_DAT_MIN     = 0ns;

    cfg.T_SU_STO_MIN     = 160ns;
    cfg.T_BUF_MIN        = 0ns;

    cfg.T_DATA_VALID_GUARD = 0ns;

    return cfg;
  endfunction

  function automatic i2c_timing_cfg_t get_ultra_fast_cfg();
    i2c_timing_cfg_t cfg;
  
    cfg.T_SCL_MIN        = 200ns; 

    cfg.T_HD_STA_MIN     = 50ns;
    cfg.T_SU_STA_MIN     = 50ns;

    cfg.T_SU_DAT_MIN     = 30ns;
    cfg.T_HD_DAT_MIN     = 10ns;

    cfg.T_SU_STO_MIN     = 50ns;
    cfg.T_BUF_MIN        = 80ns;

    cfg.T_DATA_VALID_GUARD = 10ns;

    return cfg;
  endfunction

  typedef enum int unsigned {
    MODE_STD,
    MODE_FAST,
    MODE_FMP,
    MODE_HS,
    MODE_UF
  } i2c_mode_e;


  function automatic i2c_timing_cfg_t get_cfg(i2c_mode_e mode);
    case (mode)
      MODE_STD:  return get_std_mode_cfg();
      MODE_FAST: return get_fast_mode_cfg();
      MODE_FMP:  return get_fast_mode_plus_cfg();
      MODE_HS:   return get_high_speed_cfg();
      MODE_UF:   return get_ultra_fast_cfg();
      default: begin
        return get_std_mode_cfg();
      end
    endcase
  endfunction

endpackage
