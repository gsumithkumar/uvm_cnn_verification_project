//------------------------------------------------------------------------------
// reset_seq class
// 
// This sequence is used to generate random reset sequence.
// 
// It generates a random delay and reset length, and sends a reset sequence to the DUT.
//
// This sequence is configured with the following random variables:
// - delay: The delay before the reset message is sent.
// - length: The length of the reset message.
// 
// The delay and length are random values between 0 and 255.
// Reset sequence
//
//------------------------------------------------------------------------------
class reset_seq extends uvm_sequence #(reset_seq_item);
    `uvm_object_utils(reset_seq)

    // Random delay before activate reset
    rand int unsigned delay;
    // Random reset length
    rand int unsigned length;

    // Random constraint delay must be leass than 256
    constraint delay_c {
        delay < 256;
    }
    // Random constraint length must be leass than 256
    constraint length_c {
        length < 256;
    }

    //------------------------------------------------------------------------------
    // The constructor for the sequence.
    //------------------------------------------------------------------------------
    function new(string name="reset_seq");
        super.new(name);
    endfunction : new

    //------------------------------------------------------------------------------
    // The main task to be executed within the sequence.
    //------------------------------------------------------------------------------
    task body();
        // Create sequence
        req = reset_seq_item::type_id::create("req");
        // Wait for sequencer ready
        start_item(req);
        // Randomize sequence item
        if (!(req.randomize() with {
            req.reset_delay == local::delay;
            req.reset_length == local::length;
        })) `uvm_fatal(get_name(), "Failed to randomize")
        // Send to sequencer
        finish_item(req);
        // Wait until request is completed
        get_response(rsp, req.get_transaction_id());
    endtask : body

endclass : reset_seq
