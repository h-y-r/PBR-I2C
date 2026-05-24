`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL testbench.dv_i2c.tr_mailbox
`define RAND testbench.i2c_cfg
`define TRANS testbench.test_tr

import transaction_class::*;

class rand_addr;
	rand logic [6:0] randaddr;
endclass

module tst_wrongAddr;

// Deklaracje zmiennych
parameter int NUM_TRANSACTIONS = 20;

property NACK_AFTER_WRONG_ADDR;
	@(posedge testbench.SCL)
	(`DRIVER.phase == M_ACK_ADDR) && (`DRIVER.bit_idx == `DRIVER.BIT_ACK) && (`DRIVER.curr_addr != `TARGET.ADDR_TARGET)
	|->
	(`DRIVER.ack_got == 1'b0)
endproperty	

initial begin
	Transaction tr_addr;
	rand_addr address = new();
	logic[6:0] correct_address;
	correct_address = 7'b0000111;
	logic[6:0] wrong_address;
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

	

	for (int i = 0; i < NUM_TRANSACTIONS; i++) begin
		if (!address.randomize()) begin
			$error("blad");
		end
		while(address.randaddr == 7'b0000111) begin
			if (!address.randomize()) begin
				$error("blad");
			end
		end
		#100ns;
		tr_addr = new(
	        .addr(address.randomaddr), 
	        .rwSet(0), 
	        .data_to_send({8'b00000001})
	    );

		`MAIL.put(tr_addr);
		
		#2000us;
	end

	//testy - adres o różnicy jednego bitu

	for (int i = 0; i<=6; i++) begin
		wrong_address = correct_address;
		wrong_address[i] = ~wrong_address[i];
		#100ns;
		tr_addr = new(
	        .addr(wrong_address), 
	        .rwSet(0), 
	        .data_to_send({8'b00000001})
	    );

		`MAIL.put(tr_addr);
		
		#2000us;
	end

end

chk_nackAfterWrongAddr: assert property (NACK_AFTER_WRONG_ADDR) $display("chk_nackAfterWrongAddr PASSED!");
						else $error("chk_nackAfterWrongAddr FAILED!");

endmodule