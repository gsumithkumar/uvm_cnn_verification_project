//------------------------------------------------------------------------------
// Scoreboard for the CNN Conv2D Layer testbench.
//
// This class is an implementation of the scoreboard that monitors the
// testbench and checks the behavior of the CNN convolution layer DUT.
// It provides the following features:
//
// - Monitors the reset signal to track reset events
// - Monitors the output feature maps from the DUT
// - Tracks the number of valid outputs received
// - Provides functional coverage for the convolution layer operation
// - Provides error reporting for any errors detected during simulation
//
// This class is derived from the `uvm_component` class and implements
// analysis ports for reset and CNN output monitoring.
//
// The functional coverage is provided by the `cnn_conv2d_covergrp`
// coverage group.
//
//------------------------------------------------------------------------------
// Instance analysis defines
`uvm_analysis_imp_decl(_scoreboard_reset)
`uvm_analysis_imp_decl(_scoreboard_cnn_output)

class scoreboard extends uvm_component;
    `uvm_component_utils(scoreboard)

    // Reset data instance analysis connection
    uvm_analysis_imp_scoreboard_reset #(reset_seq_item, scoreboard) m_reset_ap;
    
    // CNN output instance analysis connection
    uvm_analysis_imp_scoreboard_cnn_output #(conv2d_layer_output_seq_item, scoreboard) m_cnn_output_ap;

    // Scoreboard state variables
    int unsigned reset_valid;
    int unsigned reset_value;
    int unsigned output_count;
    int unsigned image_complete_count;
    int unsigned current_img_id;
    bit frame_active;

    //Complete Signal Handling
    int unsigned complete_delay_cycles;
    bit final_complete;
    
    
    // Coverage variables
    bit output_data_valid;
    bit complete_flag;
    logic signed [7:0] output_sample;
    

    int unsigned cvr_output_data_zero_count;
    int unsigned cvr_output_data_positive_small_count;
    int unsigned cvr_output_data_positive_medium_count;
    int unsigned cvr_output_data_positive_max_count;
    int unsigned cvr_output_data_negative_small_count;
    int unsigned cvr_output_data_negative_medium_count;
    int unsigned cvr_output_data_negative_max_count;
    //------------------------------------------------------------------------------
    // Functional coverage definitions
    //------------------------------------------------------------------------------
    covergroup cnn_conv2d_covergrp;
        // Reset coverage
        reset : coverpoint reset_value iff (reset_valid) {
            bins reset = {0};
            bins run = {1};
        }
        
        // Output valid coverage
        output_valid : coverpoint output_data_valid {
            bins valid = {1};
            bins invalid = {0};
        }
        
        // Complete signal coverage
        complete : coverpoint complete_flag {
            bins complete_asserted = {1};
            bins complete_deasserted = {0};
        }
        
        // // Output data value coverage (sample one output element)
        // output_data : coverpoint output_sample {
        //     bins zero = {8'h00};
        //     bins positive_small = {[8'h01:8'h3F]};
        //     ignore_bins positive_medium = {[8'h40:8'h7E]};
        //     ignore_bins positive_max = {8'h7F};
        //     bins negative_small = {[8'h80:8'hC0]};
        //     ignore_bins negative_medium = {[8'hC1:8'hFE]};
        //     ignore_bins negative_max = {8'hFF};
        // }
        
        // Cross coverage
        output_cross : cross output_valid, complete{
            bins valid_finished = output_cross with (output_valid == 1 && complete == 1);
            bins valid_output = output_cross with (output_valid == 1 && complete == 0);
            bins invalid_output = output_cross with (output_valid == 0 && complete == 0);
            ignore_bins no_state = output_cross with (output_valid == 0 && complete == 1);
        }
        
    endgroup

    covergroup cvr_output_data_covergrp;
        output_data : coverpoint output_sample {
            bins zero = {8'h00};
            bins positive_small = {[8'h01:8'h3F]};
            bins positive_medium = {[8'h40:8'h7E]};
            bins positive_max = {8'h7F};
            bins negative_small = {[8'h80:8'hC0]};
            bins negative_medium = {[8'hC1:8'hFE]};
            bins negative_max = {8'hFF};
        }
    endgroup

    //------------------------------------------------------------------------------
    // The constructor for the component.
    //------------------------------------------------------------------------------
    function new(string name = "scoreboard", uvm_component parent = null);
        super.new(name, parent);
        // Create coverage groups
        cnn_conv2d_covergrp = new();
        cvr_output_data_covergrp = new();
        // Initialize counters
        output_count = 0;
        image_complete_count = 0;
        current_img_id = 0;
        cvr_output_data_zero_count = 0;
        cvr_output_data_positive_small_count = 0;
        cvr_output_data_positive_medium_count = 0;
        cvr_output_data_positive_max_count = 0;
        cvr_output_data_negative_small_count = 0;
        cvr_output_data_negative_medium_count = 0;
        cvr_output_data_negative_max_count = 0;
	final_complete = 0;
	frame_active = 0;
	complete_delay_cycles = 0;
    endfunction : new

    //------------------------------------------------------------------------------
    // The build phase for the component.
    //------------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Create analysis connections
        m_reset_ap = new("m_reset_ap", this);
        m_cnn_output_ap = new("m_cnn_output_ap", this);
    endfunction : build_phase

    //------------------------------------------------------------------------------
    // The connection phase for the component.
    //------------------------------------------------------------------------------
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction : connect_phase

    //------------------------------------------------------------------------------
    // Write implementation for write_scoreboard_reset analyze port.
    //------------------------------------------------------------------------------
    virtual function void write_scoreboard_reset(reset_seq_item item);
        `uvm_info(get_name(), $sformatf("RESET_MONITOR:\n%s", item.sprint()), UVM_HIGH)
        
        // Sample reset coverage
        reset_valid = 1;
        reset_value = item.reset_value;
        cnn_conv2d_covergrp.sample();
        reset_valid = 0;
        
        // Reset state on reset assertion
        if (reset_value == 0) begin
            `uvm_info(get_name(), "Reset asserted - clearing scoreboard state", UVM_MEDIUM)
            output_count = 0;
            current_img_id = 0;
	    final_complete = 0;
	    frame_active = 0;
	    complete_delay_cycles = 0;
        end
    endfunction : write_scoreboard_reset

    //------------------------------------------------------------------------------
    // Write implementation for write_scoreboard_cnn_output analyze port.
    //------------------------------------------------------------------------------
    virtual function void write_scoreboard_cnn_output(conv2d_layer_output_seq_item item);
        `uvm_info(get_name(), $sformatf("CNN_OUTPUT_MONITOR:\n%s", item.sprint()), UVM_HIGH)
        
        // Check that image IDs are sequential
        if (item.img_id != current_img_id) begin
            `uvm_error(get_name(), $sformatf("Image ID mismatch! Expected=%0d, Received=%0d", 
                                              current_img_id, item.img_id))
        end
        
	//As soon as the 'output_data_valid' is high, the current frame observed is active.
        if(item.output_data_valid && frame_active == 0) begin
	frame_active=1;
	`uvm_info(get_name(), $sformatf("Image %0d Started ",item.img_id), UVM_MEDIUM)
	
	end
	
        // Update output count
        if (item.output_data_valid && frame_active == 1) begin
            output_count++;
            `uvm_info(get_name(), $sformatf("Received valid output #%0d for image %0d", 
                                             output_count, item.img_id), UVM_MEDIUM)
            
            // Log output values for debugging
            `uvm_info(get_name(), $sformatf("Output elements (first 4): [0]=%0d, [1]=%0d, [2]=%0d, [3]=%0d",
                                             item.output_elements[0], item.output_elements[1],
                                             item.output_elements[2], item.output_elements[3]), UVM_HIGH)

            for(int i = 0; i < 32; i++) begin
                if(item.output_elements[i] == 0) begin
                    cvr_output_data_zero_count++;
                end else if(item.output_elements[i] >= 8'h01 && item.output_elements[i] <= 8'h3F) begin
                    cvr_output_data_positive_small_count++;
                end else if(item.output_elements[i] >= 8'h40 && item.output_elements[i] <= 8'h7E) begin
                    cvr_output_data_positive_medium_count++;
                end else if(item.output_elements[i] == 8'h7F) begin
                    cvr_output_data_positive_max_count++;
                end else if(item.output_elements[i] >= 8'h80 && item.output_elements[i] <= 8'hC0) begin
                    cvr_output_data_negative_small_count++;
                end else if(item.output_elements[i] >= 8'hC1 && item.output_elements[i] <= 8'hFE) begin
                    cvr_output_data_negative_medium_count++;
                end else if(item.output_elements[i] == 8'hFF) begin
                    cvr_output_data_negative_max_count++;
                end
                output_sample = item.output_elements[i];
                cvr_output_data_covergrp.sample();
            end
        end
        
	//final_complete is the state variable that will be used to initiate the actions when frame processing is complete (based on item.complete)
	if (frame_active && item.complete && !final_complete) begin
		final_complete=1;
		complete_delay_cycles = 3;  //With value 2, there was one dump pixel occuring after the final image :-( 	
	
	end

	//Delay for output_data_valid being active even after complete=0
	if(final_complete) begin
	   if(complete_delay_cycles > 0) begin
		complete_delay_cycles--;
	end
	end
         
	//Actual Action to be done when frame processing is complete.
	if(final_complete && complete_delay_cycles == 0) begin
	     image_complete_count++;
            current_img_id++;
            `uvm_info(get_name(), $sformatf("Image %0d processing COMPLETE. Total outputs for this image: %0d", 
                                             item.img_id, output_count), UVM_MEDIUM)
            output_count = 0;
	    final_complete = 0;
	    frame_active = 0;
        end
        
        // Sample coverage
        output_data_valid = item.output_data_valid;
        complete_flag = item.complete;
        // output_sample = item.output_elements[0];  // Sample first output element
        
        cnn_conv2d_covergrp.sample();
        
    endfunction : write_scoreboard_cnn_output

    //------------------------------------------------------------------------------
    // UVM check phase
    //------------------------------------------------------------------------------
    real reset_cov, output_valid_cov, complete_cov, output_data_cov, output_cross_cov;

    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        
        // Complete simulation report
        $display("*****************************************************");
        $display("CNN Conv2D Layer Verification Results");
        $display("*****************************************************");
        $display("Number of images completed: %0d", image_complete_count);
        $display("*****************************************************");
        
        // Get individual coverpoint coverage percentages
        reset_cov = cnn_conv2d_covergrp.reset.get_inst_coverage();
        output_valid_cov = cnn_conv2d_covergrp.output_valid.get_inst_coverage();
        complete_cov = cnn_conv2d_covergrp.complete.get_inst_coverage();
        output_data_cov = cvr_output_data_covergrp.output_data.get_inst_coverage();
        output_cross_cov = cnn_conv2d_covergrp.output_cross.get_inst_coverage();
        
        // Print detailed coverage for each coverpoint
        $display("-----------------------------------------------------");
        $display("DETAILED COVERAGE BIN PERCENTAGES:");
        $display("-----------------------------------------------------");
        $display("Reset coverpoint: %0f%%", reset_cov);
        if (reset_cov < 100.0) begin
            $display("  WARNING: Reset coverpoint not at 100%%");
            $display("  Bins: reset, run");
        end
        
        $display("Output valid coverpoint: %0f%%", output_valid_cov);
        if (output_valid_cov < 100.0) begin
            $display("  WARNING: Output valid coverpoint not at 100%%");
            $display("  Bins: valid, invalid");
        end
        
        $display("Complete coverpoint: %0f%%", complete_cov);
        if (complete_cov < 100.0) begin
            $display("  WARNING: Complete coverpoint not at 100%%");
            $display("  Bins: complete_asserted, complete_deasserted");
        end
        
        $display("Output data coverpoint: %0f%%", output_data_cov);
        if (output_data_cov < 100.0) begin
            $display("  WARNING: Output data coverpoint not at 100%%");
            $display("  Bins: zero, positive_small, positive_medium, positive_max,");
            $display("        negative_small, negative_medium, negative_max");
        end
        
        $display("Output cross coverpoint: %0f%%", output_cross_cov);
        if (output_cross_cov < 100.0) begin
            $display("  WARNING: Output cross coverpoint not at 100%%");
            $display("  Bins: valid_finished, valid_output, invalid_output");
        end
        $display("-----------------------------------------------------");
        
        $display("Output data value coverage (sample one output element):");
        $display("-----------------------------------------------------");
        $display("Zero: %0d", cvr_output_data_zero_count);
        $display("Positive small: %0d", cvr_output_data_positive_small_count);
        $display("Positive medium: %0d", cvr_output_data_positive_medium_count);
        $display("Positive max: %0d", cvr_output_data_positive_max_count);
        $display("Negative small: %0d", cvr_output_data_negative_small_count);
        $display("Negative medium: %0d", cvr_output_data_negative_medium_count);
        $display("Negative max: %0d", cvr_output_data_negative_max_count);
        $display("-----------------------------------------------------");
        
        // Check functional coverage
        if (cnn_conv2d_covergrp.get_coverage() == 100.0) begin
            $display("FUNCTIONAL COVERAGE (100.0%%) PASSED....");
        end else begin
            $display("FUNCTIONAL COVERAGE: %0f%%", cnn_conv2d_covergrp.get_coverage());
            $display("Note: Some coverage bins may require specific test scenarios");
        end
        $display("*****************************************************");
        
    endfunction : check_phase

endclass : scoreboard

