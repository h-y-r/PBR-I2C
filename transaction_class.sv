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

  class test_randomizer;
    bit [6:0] address;
    rand bit rw;
    rand int readlen;
    rand logic [7:0] reg_addr;
    rand logic [7:0] data_send [$];
    Transaction tr_reg_addr;
    Transaction tr;

    constraint c_q_size {
      data_send.size() inside {[1,4]};
    }

    constraint c_reg_addr {
      reg_addr inside {[0,3]};
    }

    constraint c_read_length {
      readlen inside {[1,4]};
    }

    function new(bit [6:0] addr);
        address = addr;
    endfunction : new

    function void post_randomize();
        tr_reg_addr = new(
            .addr(address),
            .rwSet(0),
            .data_to_send({reg_addr})
        );

        tr = new(
            .addr(address),
            .rwSet(rw),
            .r_len(readlen),
            .data_to_send(data_send)
        );
    endfunction : post_randomize

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

  typedef enum logic {
    WRITE_10BIT,
    READ_10BIT
  } bit10_phase;
endpackage
