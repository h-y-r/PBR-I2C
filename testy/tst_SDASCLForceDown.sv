`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL testbench.dv_i2c.tr_mailbox
`define RAND testbench.i2c_cfg
`define TRANS testbench.test_tr

import transaction_class::*;
class data;
	rand logic [7:0] byte1;
	rand logic [7:0] byte2;
endclass

module basic_test;

// Deklaracje zmiennych
int NUM_TRANSACTIONS = testbench.NUM_TRANSACTIONS;

property ACK_AFTER_DATA;
	@(posedge testbench.SCL)
	(`DRIVER.phase == M_DATA_TX && (`DRIVER.bit_idx == 0))
	|->
	##1 (testbench.SDA == 1'b0);
endproperty	

initial begin
	Transaction tr;
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
	`DRIVER.DATA_HOLD_TIME = `RAND.low_period - `RAND.setup_time;	
	#100ns;
	for (int i = 0; i < NUM_TRANSACTIONS; i++) begin
		if (!random_bytes.randomize()) begin
			$error("blad - randomizacja danych");
		end

		force testbench.SDA = 1'b0;
		force testbench.SCL = 1'b0;

		testbench.rst = 0;
		#10;
		testbench.rst = 1;
		#10;

		release testbench.SDA;
		release testbench.SCL;

		#100;

		tr = new(
	        .addr(7'b0010000), 
	        .rwSet(0), 
	        .data_to_send({8'd0, random_bytes.byte2})
	    );
		
		`MAIL.put(tr);
		wait(`DRIVER.phase == M_START);
		wait(`DRIVER.phase == M_DONE);
		#50;
	end
	$finish();
end

chk_forceSDASCL:	assert property (ACK_AFTER_DATA) $display("chk_forceSDASCL PASSED!");
					else $error("chk_forceSDASCL FAILED!");

endmodule
