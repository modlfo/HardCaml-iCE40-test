open Hardcaml
open Hardcaml.Signal

(* Declares the top level inputs and outputs*)
let clock = input "CLK" 1
let button1 = input "BUT1" 1
let button2 = input "BUT2" 1
let led1 = output "LED1"
let led2 = output "LED2"

(* Using the button 1 as reset, otherwise the simulator does not initialize the registers *)
let reset = ~: button1

(* These are the signals of the iCE40-DAC board *)
let dac = output "DAC"
let dac_clk = output "DAC_CLK"


(* Creates a counter of a given width *)
let counter ~width =
  let d = wire width in
  let spec = Hardcaml.Reg_spec.create ~reset () ~clock in
  let q = reg spec ~enable:vdd (d +:. 1) in
  let () = d <== q in
  q

(* Takes the upper n bits of a signal *)
let upper ~n s =
  let m = (width s) in
  select s (m - 1) (m - n)


(* Creates a PWM of n bits controlled with a signal p.
   The number of bits must be >= than the bits of the control signal *)
let pwm ~n p =
  let count = counter ~width:n in
  let up_part = upper ~n:(width p) count in
  p >: up_part


(* This function generates a lookup table to control
   the brightness of the LED is a more linear way *)
let brightness i =
  let rec pow_2_n n =
    if n = 0 then 1 else 2 * pow_2_n (n - 1)
  in
  (* calculates size*(i/size)^2*)
  let calc size i =
    let fsize = float_of_int size in
    let n = (float_of_int i) /. fsize in
    int_of_float (n *. n *. fsize)
  in
  let w = width i in
  let size = pow_2_n w in
  let table = List.init size (fun i -> consti ~width:w (calc size i)) in
  mux i table

let top =
  (* Generates a saw of 8 bits using an internal counter of 27 bits *)
  let saw = upper ~n:4 (counter ~width:27) in
  (* Generates a PWM of 12 bits controlled by the saw signal *)
  pwm ~n:12 (brightness saw)

(* Generates a Saw wave to send to the DAC *)
let wave =
  let saw = upper ~n:8 (counter ~width:12) in
  saw

(* Generates the clock for the DAC*)
let clk_2 = msb (counter ~width:2)

let () =
  (* Write the top.v file *)
  let circuit = Hardcaml.Circuit.create_exn ~name:"top" [ led1 top; dac_clk clk_2; dac wave ] in
  Rtl.output Verilog circuit

