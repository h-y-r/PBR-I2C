`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL testbench.dv_i2c.tr_mailbox
`define RAND testbench.i2c_cfg
`define TRANS testbench.test_tr
module tst_reservedAddr;

bit DIFFERENT_BUS_FORMAT_ENABLE = 1'b0;
bit RESERVED_ADDR_ENABLE = 1'b0;
bit CBUS_ADDR_ENABLE = 1'b0;
bit START_BYTE_ENABLE = 1'b0;

// Deklaracje zmiennych
property DIFFERENT_BUS_FORMAT;
	@(posedge testbench.SCL)
	(`DRIVER.phase == M_ACK_ADDR) && (`DRIVER.bit_idx == `DRIVER.BIT_ACK) && (DIFFERENT_BUS_FORMAT_ENABLE)
	|->
	(`DRIVER.ack_got == 1'b0)
endproperty

property RESERVED_ADDR;
	@(posedge testbench.SCL)
	(`DRIVER.phase == M_ACK_ADDR) && (`DRIVER.bit_idx == `DRIVER.BIT_ACK) && (RESERVED_ADDR_ENABLE)
	|->
	(`DRIVER.ack_got == 1'b0)
endproperty	

property CBUS_ADDR;
	@(posedge testbench.SCL)
	(`DRIVER.phase == M_ACK_ADDR) && (`DRIVER.bit_idx == `DRIVER.BIT_ACK) && (CBUS_ADDR_ENABLE)
	|->
	(`DRIVER.ack_got == 1'b0)
endproperty

property START_BYTE;
	@(posedge testbench.SCL)
	(`DRIVER.phase == M_ACK_ADDR) && (`DRIVER.bit_idx == `DRIVER.BIT_ACK) && (START_BYTE_ENABLE)
	|->
	(`DRIVER.ack_got == 1'b0)
endproperty


initial begin
	Transaction tr;
	static logic [7:0] CBUSbyte = 8'b0;

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
	//start byte - no device is allowed to ack
	START_BYTE_ENABLE = 1'b1;
	tr = new(
        .addr(7'b0000000),
        .rwSet(1),
        .r_len(2)
    );
	
    `MAIL.put(tr);
    wait(`DRIVER.phase == M_IDLE);
	START_BYTE_ENABLE = 1'b0;

	//address reserved for cbus devices - expected nack
	CBUS_ADDR_ENABLE = 1'b1;
	tr = new(
        .addr(7'b0000001),
        .rwSet(1),
        .r_len(2)
    );
	
    `MAIL.put(tr);
    wait(`DRIVER.phase == M_IDLE);


    tr = new(
        .addr(7'b0000001),
        .rwSet(0),
        .data_to_send({CBUSbyte})
    );

    `MAIL.put(tr);
    wait(`DRIVER.phase == M_IDLE);

	CBUS_ADDR_ENABLE = 1'b0;

	//reserved address for different bus format - expected nack
	DIFFERENT_BUS_FORMAT_ENABLE = 1'b1;
	tr = new(
        .addr(7'b0000010),
        .rwSet(1),
        .r_len(2)
    );
	
    `MAIL.put(tr);
    wait(`DRIVER.phase == M_IDLE);


    tr = new(
        .addr(7'b0000010),
        .rwSet(0),
        .data_to_send({8'd0})
    );

    `MAIL.put(tr);
    wait(`DRIVER.phase == M_IDLE);
    DIFFERENT_BUS_FORMAT_ENABLE = 1'b0;

    //address reserved for future purpouses - expected nack
    RESERVED_ADDR_ENABLE = 1'b1;
    tr = new(
        .addr(7'b0000011),
        .rwSet(1),
        .r_len(2)
    );
    
    `MAIL.put(tr);
    wait(`DRIVER.phase == M_IDLE);

    tr = new(
        .addr(7'b0000011),
        .rwSet(0),
        .data_to_send({8'd0})
    );
    
    `MAIL.put(tr);
    wait(`DRIVER.phase == M_IDLE);
    RESERVED_ADDR_ENABLE = 1'b0;


	$finish();
end

chk_differentBusFormat: assert property (DIFFERENT_BUS_FORMAT) $display("chk_differentBusFormat PASSED!");
						else $error("chk_differentBusFormat FAILED!");

chk_reservedAddr: assert property (RESERVED_ADDR) $display("chk_reservedAddr PASSED!");
						else $error("chk_reservedAddr FAILED!");

chk_CBUSAddr: assert property (CBUS_ADDR) $display("chk_CBUSAddr PASSED!");
						else $error("chk_CBUSAddr FAILED!");

chk_startByte: assert property (START_BYTE) $display("chk_startByte PASSED!");
						else $error("chk_startByte FAILED!");


endmodule