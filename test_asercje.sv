`define MAIL top_tb.dv_i2c.tr_mailbox

module test;

// Deklaracje zmiennych
bit signal;
..

bit EXPECTED_START_STOP;

event assert_chk_startStopCondition;

initial begin
	// Konfiguracja
	tr = new();
	// konfiguracja divera - czasy
	
	#100ns;
	
	// zaczynamy testowanie wlasciwe
	std::randomize(regAddr) with dist {}
	tr = new(.......);
	
	`MAIL.put(tr);
		
	
	@(negedge sda) time1 = $realtime();
	@(negedge scl) time2 = $realtime();
	EXPECTED_START_STOP = assert((time2 - time1) < 4us) && ((time2 - time1) > 100ns);
	-> assert_chk_startStopCondition;

	wait (i2cdriver.state == M_ACK_RCV) EXPECTED_START_STOP = !SDA;
	
	i2ctarget.digital.synchronizer.q == 1'b1;
	
	
	#25us;
	$finish();
end


always @(assert_chk_startStopCondition) begin
	chk_startStopCondition 	:	assert(EXPECTED_START_STOP) $display("chk_startStopCondition PASSED!");
					$error("chk_startStopCondition FAILED!")
end

endmodule
