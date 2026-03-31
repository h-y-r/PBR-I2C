package transaction_class;
  class Transaction;
    bit [6:0] address;
    bit rw;
    int readlen;
    bit [7:0]data[$];

    function new(bit [6:0] addr, bit rwSet, bit [7:0] data_to_send [$] = {}, int r_len = 0);
      address = addr;
      rw = rwSet;
      data = data_to_send;
      readlen = r_len;
    endfunction : new
  endclass

  typedef enum logic [3:0] {
    M_IDLE,      
    M_START,     
    M_ADDR,      
    M_ACK_ADDR,  
    M_DATA_TX,   
    M_ACK_DATA,  
    M_DATA_RX,   
    M_STOP,      
    M_DONE,      
    M_ERROR,      
    M_ADDR_10BIT, 
    M_DEVICE_ID, 
    M_SEND_ADDR_FOR_ID,
    M_SR,
    M_GENERAL_CALL
  } master_phase_e;

  typedef enum logic [1:0] {
    RESET,
    WRITE,
    ILLEGAL,
    HARDWARE
  } call_phase;
endpackage
