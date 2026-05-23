//--------------------------------------------------------------------------------
//Description:
//
//   conv_output_monitor
//   -----------
//   This UVM monitor passively observes the CNN convolution-layer DUT interface
//   through the virtual interface handle stored in cnn_conv_config. 
//
//   The DUT produces 32 parallel convolution outputs every time
//   output_data_valid is asserted. This monitor samples all 32 output lanes
//   on the rising edge of clk when output_data_valid==1, packages them into
//   a cnn_conv_mont_item transaction, and publishes that transaction to other
//   verification components (scoreboard / coverage) via an analysis port.

//--------------------------------------------------------------------------------

class conv_output_monitor extends uvm_monitor;
    `uvm_component_utils(conv_output_monitor)

    // Convolution Layer UVC configuration
    cnn_conv_output_config m_config;

    // Analysis port to scoreboard / coverage
    uvm_analysis_port #(cnn_conv_mont_item) m_analysis_port;

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // build_phase:
    //
    // Purpose:
    //   - Retrieve the UVC configuration object from uvm_config_db.
    //   - Create (construct) the analysis port.
    //   - Initialize bookkeeping variables (img_id).
    //--------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(cnn_conv_output_config)::get(this,"","cnn_conv_output_config", m_config))
            `uvm_fatal(get_name(), "Cannot find cnn_conv_config")

       m_analysis_port = new("m_convolution_analysis_port", this);
       img_id=0;
    endfunction

    //--------------------------------------------------------------------------
    // run_phase:
    //
    // High-level operation:
    //   1) Wait for rising edge of clk (synchronize sampling).
    //   2) Check if DUT output_data_valid == 1 (means outputs are meaningful).
    //   3) If valid:
    //       a) Create a new monitor transaction (cnn_conv_mont_item).
    //       b) Fill in metadata (img_id, valid flag, complete flag, status).
    //       c) Copy all 32 output lanes into the transaction.
    //       d) Write transaction out on analysis port.
    //       e) If complete asserted, increment img_id for next image.
    //--------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        cnn_conv_mont_item img_transac;    

        forever begin
        @(posedge m_config.m_vif.clk);

      // SAMPLE ONLY WHEN VALID 
      if (m_config.m_vif.output_data_valid) begin
        img_transac = cnn_conv_mont_item::type_id::create("img_transac", this);

        img_transac.img_id            = img_id;
        img_transac.output_data_valid = 1'b1;
        img_transac.complete          = m_config.m_vif.complete;

        img_transac.conv_status = (img_transac.complete) ? IMAGE_COMPLETE : IMAGE_PROCESSING;

        // Capture all 32 channels of outputs
        for (int k = 0; k < 32; k++) begin
          img_transac.output_elements[k] = m_config.m_vif.output_elements[k];
        end

        // Publish to scoreboard
        m_analysis_port.write(img_transac);

        // If this was the last output of the image, move to next image id
        if (m_config.m_vif.complete) begin
          img_id++;
        end
      end
    end
            
    endtask

endclass : conv_output_monitor