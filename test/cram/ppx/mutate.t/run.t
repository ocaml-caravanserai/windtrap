The mutation rewriter's expansions and refusals, as pp.exe prints them
(see ../coverage.t).

  $ export OCAML_COLOR=never
  $ mut() { ../pp.exe -apply windtrap_mutate "$@"; }

A mutated file opens with a module that registers its sites, shown here
in full. The file is mutated under its own name:

  $ mut --impl ./fixture_input_name.ml
  [@@@ocaml.text "/*"]
  module Windtrap_mut_________fixture_input_name___ml =
    struct
      type site = Windtrap_runtime.Mutate.site =
        {
        line: int ;
        col: int ;
        end_line: int ;
        end_col: int ;
        rewrite: string ;
        before: string ;
        after: string ;
        dismissed: string option }
      type 'a operands = ('a * 'a)
      let ___windtrap_armed___ =
        Windtrap_runtime.Mutate.register ~file:"./fixture_input_name.ml"
          ~digest:(Some "9bbb82795a1e351d9fa7ce6919db5ddd")
          ~sites:[|{
                     line = 5;
                     col = 34;
                     end_line = 5;
                     end_col = 35;
                     rewrite = "int";
                     before = "0";
                     after = "1";
                     dismissed = None
                   };{
                       line = 5;
                       col = 27;
                       end_line = 5;
                       end_col = 28;
                       rewrite = "int";
                       before = "1";
                       after = "0";
                       dismissed = None
                     };{
                         line = 5;
                         col = 16;
                         end_line = 5;
                         end_col = 21;
                         rewrite = "ge";
                         before = "n > 0";
                         after = "n >= 0";
                         dismissed = None
                       };{
                           line = 5;
                           col = 20;
                           end_line = 5;
                           end_col = 21;
                           rewrite = "int";
                           before = "0";
                           after = "1";
                           dismissed = None
                         }|]
    end
  [@@@ocaml.text "/*"]
  let sign n =
    if
      let (__windtrap_mut_2_l, __windtrap_mut_2_r) =
        ((n,
           (if
              Windtrap_mut_________fixture_input_name___ml.___windtrap_armed___
                3
            then 1
            else 0)) : _ Windtrap_mut_________fixture_input_name___ml.operands) in
      (if Windtrap_mut_________fixture_input_name___ml.___windtrap_armed___ 2
       then Stdlib.not (__windtrap_mut_2_r > __windtrap_mut_2_l)
       else __windtrap_mut_2_l > __windtrap_mut_2_r)
    then
      (if Windtrap_mut_________fixture_input_name___ml.___windtrap_armed___ 1
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_input_name___ml.___windtrap_armed___ 0
      then 1
      else 0

The digest is that of the file that the rewriter reads under the input
name. A file that it cannot read gives no digest:

  $ mut -loc-filename lib/nothere.ml --impl ./fixture_input_name.ml | grep -e '~file' -e '~digest'
        Windtrap_runtime.Mutate.register ~file:"lib/nothere.ml" ~digest:None

Every other expansion shows that module condensed by elide.exe to its
file and its sites: where each starts and ends, the rewrite, the text
before and after, and the reason of a dismissed site.

  $ mut --impl ./fixture_all_dismissed.ml | ../elide.exe
  mutation sites of "./fixture_all_dismissed.ml" in Windtrap_mut_________fixture_all_dismissed___ml:
    0: 9:7-9:38 "int" "16" -> "17", dismissed "a capacity"
    1: 8:5-8:16 "ge" "want > 16" -> "want >= 16", dismissed "both arms yield 16 at the boundary"
  let cap want =
    if ((want > 16)[@mutate off "both arms yield 16 at the boundary"])
    then want
    else ((16)[@mutate off "a capacity"])

  $ mut --impl ./fixture_ari.ml | ../elide.exe
  mutation sites of "./fixture_ari.ml" in Windtrap_mut_________fixture_ari___ml, with type ints, type floats:
    0: 5:14-5:19 "sub" "a + b" -> "a - b"
    1: 6:15-6:20 "add" "a - b" -> "a + b"
    2: 7:15-7:21 "fsub" "a +. b" -> "a -. b"
    3: 8:16-8:22 "fadd" "a -. b" -> "a +. b"
    4: 13:13-13:18 "sub" "1 + 2" -> "1 - 2"
    5: 16:15-16:17 "pos" "- x" -> "x"
    6: 17:17-17:28 "div" "(a + b) * 2" -> "(a + b) / 2"
    7: 17:17-17:24 "sub" "a + b" -> "a - b"
  let sum a b =
    let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
      ((a, b) : Windtrap_mut_________fixture_ari___ml.ints) in
    if Windtrap_mut_________fixture_ari___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_l - __windtrap_mut_0_r
    else __windtrap_mut_0_l + __windtrap_mut_0_r
  let diff a b =
    let (__windtrap_mut_1_l, __windtrap_mut_1_r) =
      ((a, b) : Windtrap_mut_________fixture_ari___ml.ints) in
    if Windtrap_mut_________fixture_ari___ml.___windtrap_armed___ 1
    then __windtrap_mut_1_l + __windtrap_mut_1_r
    else __windtrap_mut_1_l - __windtrap_mut_1_r
  let fsum a b =
    let (__windtrap_mut_2_l, __windtrap_mut_2_r) =
      ((a, b) : Windtrap_mut_________fixture_ari___ml.floats) in
    if Windtrap_mut_________fixture_ari___ml.___windtrap_armed___ 2
    then __windtrap_mut_2_l -. __windtrap_mut_2_r
    else __windtrap_mut_2_l +. __windtrap_mut_2_r
  let fdiff a b =
    let (__windtrap_mut_3_l, __windtrap_mut_3_r) =
      ((a, b) : Windtrap_mut_________fixture_ari___ml.floats) in
    if Windtrap_mut_________fixture_ari___ml.___windtrap_armed___ 3
    then __windtrap_mut_3_l +. __windtrap_mut_3_r
    else __windtrap_mut_3_l -. __windtrap_mut_3_r
  let origin =
    let (__windtrap_mut_4_l, __windtrap_mut_4_r) =
      ((1, 2) : Windtrap_mut_________fixture_ari___ml.ints) in
    if Windtrap_mut_________fixture_ari___ml.___windtrap_armed___ 4
    then __windtrap_mut_4_l - __windtrap_mut_4_r
    else __windtrap_mut_4_l + __windtrap_mut_4_r
  let negate x =
    let __windtrap_mut_5_p : Stdlib.Int.t = x in
    if Windtrap_mut_________fixture_ari___ml.___windtrap_armed___ 5
    then __windtrap_mut_5_p
    else - __windtrap_mut_5_p
  let scaled a b =
    let (__windtrap_mut_6_l, __windtrap_mut_6_r) =
      (((let (__windtrap_mut_7_l, __windtrap_mut_7_r) =
           ((a, b) : Windtrap_mut_________fixture_ari___ml.ints) in
         if Windtrap_mut_________fixture_ari___ml.___windtrap_armed___ 7
         then __windtrap_mut_7_l - __windtrap_mut_7_r
         else __windtrap_mut_7_l + __windtrap_mut_7_r), 2) : Windtrap_mut_________fixture_ari___ml.ints) in
    if Windtrap_mut_________fixture_ari___ml.___windtrap_armed___ 6
    then __windtrap_mut_6_l / __windtrap_mut_6_r
    else __windtrap_mut_6_l * __windtrap_mut_6_r

  $ mut --impl ./fixture_ari_scope.ml | ../elide.exe
  mutation sites of "./fixture_ari_scope.ml" in Windtrap_mut_________fixture_ari_scope___ml, with type ints:
    0: 10:17-10:22 "sub" "a + b" -> "a - b"
    1: 11:20-11:25 "sub" "a + b" -> "a - b"
    2: 14:2-14:8 "fsub" "a +. b" -> "a -. b"
  module M = struct let x = 1 end
  let pinned a b =
    let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
      ((a, b) : Windtrap_mut_________fixture_ari_scope___ml.ints) in
    if Windtrap_mut_________fixture_ari_scope___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_l - __windtrap_mut_0_r
    else __windtrap_mut_0_l + __windtrap_mut_0_r
  let opened a b =
    let open M in
      let (__windtrap_mut_1_l, __windtrap_mut_1_r) = (a, b) in
      if Windtrap_mut_________fixture_ari_scope___ml.___windtrap_armed___ 1
      then __windtrap_mut_1_l - __windtrap_mut_1_r
      else __windtrap_mut_1_l + __windtrap_mut_1_r
  let let_opened a b =
    let open M in
      let (__windtrap_mut_2_l, __windtrap_mut_2_r) = (a, b) in
      if Windtrap_mut_________fixture_ari_scope___ml.___windtrap_armed___ 2
      then __windtrap_mut_2_l -. __windtrap_mut_2_r
      else __windtrap_mut_2_l +. __windtrap_mut_2_r

  $ mut --impl ./fixture_mul.ml | ../elide.exe
  mutation sites of "./fixture_mul.ml" in Windtrap_mut_________fixture_mul___ml, with type ints, type floats:
    0: 6:16-6:21 "div" "a * b" -> "a / b"
    1: 7:17-7:22 "mul" "a / b" -> "a * b"
    2: 8:17-8:24 "mod" "a mod b" -> "a * b"
    3: 9:17-9:23 "fdiv" "a *. b" -> "a /. b"
    4: 10:18-10:24 "fmul" "a /. b" -> "a *. b"
    5: 11:15-11:23 "lor" "a land b" -> "a lor b"
    6: 12:17-12:24 "land" "a lor b" -> "a land b"
    7: 13:17-13:25 "xor" "a lxor b" -> "a land b"
    8: 14:15-14:22 "lsr" "a lsl b" -> "a lsr b"
    9: 15:16-15:23 "lsl" "a lsr b" -> "a lsl b"
    10: 16:16-16:23 "asr" "a asr b" -> "a lsl b"
    11: 19:18-19:27 "div" "(a * b) * c" -> "(a * b) / c"
    12: 20:18-20:27 "mul" "(a * b) / c" -> "(a * b) * c"
    13: 20:18-20:23 "div" "a * b" -> "a / b"
    14: 21:16-21:27 "mod" "(a / b) mod c" -> "(a / b) * c"
    15: 21:16-21:21 "mul" "a / b" -> "a * b"
    16: 22:19-22:36 "xor" "(a land b) lxor c" -> "(a land b) land c"
    17: 22:19-22:29 "lor" "a land b" -> "a lor b"
    18: 23:20-23:35 "lsl" "(a asr b) lsr c" -> "(a asr b) lsl c"
    19: 23:20-23:29 "asr" "a asr b" -> "a lsl b"
    20: 26:15-26:28 "lsr" "x lsl (1 lsl 2)" -> "x lsr (1 lsl 2)"
    21: 26:21-26:28 "lsr" "1 lsl 2" -> "1 lsr 2"
    22: 26:21-26:22 "int" "1" -> "0"
    23: 26:27-26:28 "int" "2" -> "3"
    24: 27:18-27:33 "lsr" "(x lsl 1) lsl 2" -> "(x lsl 1) lsr 2"
    25: 27:25-27:26 "int" "1" -> "0"
    26: 27:32-27:33 "int" "2" -> "3"
    27: 31:17-31:26 "div" "a * b" -> "a / b"
    28: 32:32-32:33 "int" "2" -> "3"
    29: 36:15-36:20 "div" "x * 2" -> "x / 2"
    30: 37:19-37:26 "lsr" "x lsl 2" -> "x lsr 2"
    31: 37:25-37:26 "int" "2" -> "3"
    32: 40:11-40:19 "div" "4 * 1024" -> "4 / 1024"
    33: 41:20-41:27 "div" "a * b" -> "a / b", dismissed "the product is a size"
    34: 42:16-42:21 "div" "x * 0" -> "x / 0"
    35: 44:41-44:48 "div" "a * b" -> "a / b"
  let times a b =
    let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
      ((a, b) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_l / __windtrap_mut_0_r
    else __windtrap_mut_0_l * __windtrap_mut_0_r
  let divide a b =
    let (__windtrap_mut_1_l, __windtrap_mut_1_r) =
      ((a, b) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 1
    then __windtrap_mut_1_l * __windtrap_mut_1_r
    else __windtrap_mut_1_l / __windtrap_mut_1_r
  let modulo a b =
    let (__windtrap_mut_2_l, __windtrap_mut_2_r) =
      ((a, b) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 2
    then __windtrap_mut_2_l * __windtrap_mut_2_r
    else __windtrap_mut_2_l mod __windtrap_mut_2_r
  let ftimes a b =
    let (__windtrap_mut_3_l, __windtrap_mut_3_r) =
      ((a, b) : Windtrap_mut_________fixture_mul___ml.floats) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 3
    then __windtrap_mut_3_l /. __windtrap_mut_3_r
    else __windtrap_mut_3_l *. __windtrap_mut_3_r
  let fdivide a b =
    let (__windtrap_mut_4_l, __windtrap_mut_4_r) =
      ((a, b) : Windtrap_mut_________fixture_mul___ml.floats) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 4
    then __windtrap_mut_4_l *. __windtrap_mut_4_r
    else __windtrap_mut_4_l /. __windtrap_mut_4_r
  let both a b =
    let (__windtrap_mut_5_l, __windtrap_mut_5_r) =
      ((a, b) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 5
    then __windtrap_mut_5_l lor __windtrap_mut_5_r
    else __windtrap_mut_5_l land __windtrap_mut_5_r
  let either a b =
    let (__windtrap_mut_6_l, __windtrap_mut_6_r) =
      ((a, b) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 6
    then __windtrap_mut_6_l land __windtrap_mut_6_r
    else __windtrap_mut_6_l lor __windtrap_mut_6_r
  let differ a b =
    let (__windtrap_mut_7_l, __windtrap_mut_7_r) =
      ((a, b) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 7
    then __windtrap_mut_7_l land __windtrap_mut_7_r
    else __windtrap_mut_7_l lxor __windtrap_mut_7_r
  let left a b =
    let (__windtrap_mut_8_l, __windtrap_mut_8_r) =
      ((a, b) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 8
    then __windtrap_mut_8_l lsr __windtrap_mut_8_r
    else __windtrap_mut_8_l lsl __windtrap_mut_8_r
  let right a b =
    let (__windtrap_mut_9_l, __windtrap_mut_9_r) =
      ((a, b) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 9
    then __windtrap_mut_9_l lsl __windtrap_mut_9_r
    else __windtrap_mut_9_l lsr __windtrap_mut_9_r
  let arith a b =
    let (__windtrap_mut_10_l, __windtrap_mut_10_r) =
      ((a, b) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 10
    then __windtrap_mut_10_l lsl __windtrap_mut_10_r
    else __windtrap_mut_10_l asr __windtrap_mut_10_r
  let chain a b c =
    let (__windtrap_mut_11_l, __windtrap_mut_11_r) =
      (((a * b), c) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 11
    then __windtrap_mut_11_l / __windtrap_mut_11_r
    else __windtrap_mut_11_l * __windtrap_mut_11_r
  let mixed a b c =
    let (__windtrap_mut_12_l, __windtrap_mut_12_r) =
      (((let (__windtrap_mut_13_l, __windtrap_mut_13_r) =
           ((a, b) : Windtrap_mut_________fixture_mul___ml.ints) in
         if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 13
         then __windtrap_mut_13_l / __windtrap_mut_13_r
         else __windtrap_mut_13_l * __windtrap_mut_13_r), c) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 12
    then __windtrap_mut_12_l * __windtrap_mut_12_r
    else __windtrap_mut_12_l / __windtrap_mut_12_r
  let two a b c =
    let (__windtrap_mut_14_l, __windtrap_mut_14_r) =
      (((let (__windtrap_mut_15_l, __windtrap_mut_15_r) =
           ((a, b) : Windtrap_mut_________fixture_mul___ml.ints) in
         if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 15
         then __windtrap_mut_15_l * __windtrap_mut_15_r
         else __windtrap_mut_15_l / __windtrap_mut_15_r), c) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 14
    then __windtrap_mut_14_l * __windtrap_mut_14_r
    else __windtrap_mut_14_l mod __windtrap_mut_14_r
  let masked a b c =
    let (__windtrap_mut_16_l, __windtrap_mut_16_r) =
      (((let (__windtrap_mut_17_l, __windtrap_mut_17_r) =
           ((a, b) : Windtrap_mut_________fixture_mul___ml.ints) in
         if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 17
         then __windtrap_mut_17_l lor __windtrap_mut_17_r
         else __windtrap_mut_17_l land __windtrap_mut_17_r), c) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 16
    then __windtrap_mut_16_l land __windtrap_mut_16_r
    else __windtrap_mut_16_l lxor __windtrap_mut_16_r
  let shifted a b c =
    let (__windtrap_mut_18_l, __windtrap_mut_18_r) =
      (((let (__windtrap_mut_19_l, __windtrap_mut_19_r) =
           ((a, b) : Windtrap_mut_________fixture_mul___ml.ints) in
         if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 19
         then __windtrap_mut_19_l lsl __windtrap_mut_19_r
         else __windtrap_mut_19_l asr __windtrap_mut_19_r), c) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 18
    then __windtrap_mut_18_l lsl __windtrap_mut_18_r
    else __windtrap_mut_18_l lsr __windtrap_mut_18_r
  let nested x =
    let (__windtrap_mut_20_l, __windtrap_mut_20_r) =
      ((x,
         (let (__windtrap_mut_21_l, __windtrap_mut_21_r) =
            (((if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 22
               then 0
               else 1),
               (if
                  Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 23
                then 3
                else 2)) : Windtrap_mut_________fixture_mul___ml.ints) in
          if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 21
          then __windtrap_mut_21_l lsr __windtrap_mut_21_r
          else __windtrap_mut_21_l lsl __windtrap_mut_21_r)) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 20
    then __windtrap_mut_20_l lsr __windtrap_mut_20_r
    else __windtrap_mut_20_l lsl __windtrap_mut_20_r
  let bracketed x =
    let (__windtrap_mut_24_l, __windtrap_mut_24_r) =
      (((x lsl
           (if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 25
            then 0
            else 1)),
         (if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 26
          then 3
          else 2)) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 24
    then __windtrap_mut_24_l lsr __windtrap_mut_24_r
    else __windtrap_mut_24_l lsl __windtrap_mut_24_r
  let prefix a b =
    let (__windtrap_mut_27_l, __windtrap_mut_27_r) =
      ((a, b) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 27
    then __windtrap_mut_27_l / __windtrap_mut_27_r
    else __windtrap_mut_27_l * __windtrap_mut_27_r
  let partial l =
    List.map
      (( *
         ) (if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 28
            then 3
            else 2)) l
  let qualified a b = Stdlib.( * ) a b
  let scaled x =
    let (__windtrap_mut_29_l, __windtrap_mut_29_r) =
      ((x, 2) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 29
    then __windtrap_mut_29_l / __windtrap_mut_29_r
    else __windtrap_mut_29_l * __windtrap_mut_29_r
  let quadrupled x =
    let (__windtrap_mut_30_l, __windtrap_mut_30_r) =
      ((x,
         (if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 31
          then 3
          else 2)) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 30
    then __windtrap_mut_30_l lsr __windtrap_mut_30_r
    else __windtrap_mut_30_l lsl __windtrap_mut_30_r
  let size =
    let (__windtrap_mut_32_l, __windtrap_mut_32_r) =
      ((4, 1024) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 32
    then __windtrap_mut_32_l / __windtrap_mut_32_r
    else __windtrap_mut_32_l * __windtrap_mut_32_r
  let dismissed a b = ((a * b)[@mutate off "the product is a size"])
  let by_zero x =
    let (__windtrap_mut_34_l, __windtrap_mut_34_r) =
      ((x, 0) : Windtrap_mut_________fixture_mul___ml.ints) in
    if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 34
    then __windtrap_mut_34_l / __windtrap_mut_34_r
    else __windtrap_mut_34_l * __windtrap_mut_34_r
  let logged a b = Logs.debug (fun m -> m "%d" (a * b))
  let failed a b =
    failwith
      (string_of_int
         (let (__windtrap_mut_35_l, __windtrap_mut_35_r) =
            ((a, b) : Windtrap_mut_________fixture_mul___ml.ints) in
          if Windtrap_mut_________fixture_mul___ml.___windtrap_armed___ 35
          then __windtrap_mut_35_l / __windtrap_mut_35_r
          else __windtrap_mut_35_l * __windtrap_mut_35_r))

  $ mut --impl ./fixture_counter.ml | ../elide.exe
  mutation sites of "./fixture_counter.ml" in Windtrap_mut_________fixture_counter___ml:
    0: 5:11-5:17 "decr" "incr r" -> "decr r"
    1: 6:13-6:19 "incr" "decr r" -> "incr r"
    2: 7:35-7:48 "decr" "Atomic.incr a" -> "Atomic.decr a"
    3: 8:37-8:50 "incr" "Atomic.decr a" -> "Atomic.incr a"
    4: 9:40-9:46 "decr" "incr c" -> "decr c"
    5: 10:24-10:30 "decr" "incr r" -> "decr r"
    6: 11:30-11:36 "decr" "incr r" -> "decr r"
    7: 15:16-15:28 "decr" "incr s.count" -> "decr s.count"
    8: 16:20-16:38 "decr" "incr (r : int ref)" -> "decr (r : int ref)"
    9: 19:2-19:8 "del" "incr r" -> "()"
    10: 19:2-19:8 "decr" "incr r" -> "decr r"
    11: 22:27-22:33 "del" "incr r" -> "()"
    12: 22:27-22:33 "decr" "incr r" -> "decr r"
    13: 22:20-22:21 "not" "c" -> "not c"
    14: 26:9-26:20 "decr" "incr loaded" -> "decr loaded"
    15: 27:18-27:26 "decr" "incr r" -> "decr r", dismissed "the count is a statistic"
    16: 37:33-37:34 "int" "0" -> "1"
  let up r =
    if Windtrap_mut_________fixture_counter___ml.___windtrap_armed___ 0
    then decr r
    else incr r
  let down r =
    if Windtrap_mut_________fixture_counter___ml.___windtrap_armed___ 1
    then incr r
    else decr r
  let atomic_up (a : int Atomic.t) =
    if Windtrap_mut_________fixture_counter___ml.___windtrap_armed___ 2
    then Atomic.decr a
    else Atomic.incr a
  let atomic_down (a : int Atomic.t) =
    if Windtrap_mut_________fixture_counter___ml.___windtrap_armed___ 3
    then Atomic.incr a
    else Atomic.decr a
  let opened (c : int Atomic.t) =
    let open Atomic in
      if Windtrap_mut_________fixture_counter___ml.___windtrap_armed___ 4
      then decr c
      else incr c
  let int_opened r =
    let open Int in
      if Windtrap_mut_________fixture_counter___ml.___windtrap_armed___ 5
      then decr r
      else incr r
  let printf_opened r =
    let open Printf in
      if Windtrap_mut_________fixture_counter___ml.___windtrap_armed___ 6
      then decr r
      else incr r
  type state = {
    count: int ref }
  let counted s =
    if Windtrap_mut_________fixture_counter___ml.___windtrap_armed___ 7
    then decr s.count
    else incr s.count
  let constrained r =
    if Windtrap_mut_________fixture_counter___ml.___windtrap_armed___ 8
    then decr (r : int ref)
    else incr (r : int ref)
  let statement r x =
    (if Windtrap_mut_________fixture_counter___ml.___windtrap_armed___ 9
     then ((())[@ocaml.warning "-41-42"])
     else
       (if Windtrap_mut_________fixture_counter___ml.___windtrap_armed___ 10
        then decr r
        else incr r;
        ((())
        [@ocaml.warning "-41-42"])) : Stdlib.Unit.t);
    x
  let branch c r =
    if
      let __windtrap_mut_13_p : Stdlib.Bool.t = c in
      (if Windtrap_mut_________fixture_counter___ml.___windtrap_armed___ 13
       then Stdlib.not __windtrap_mut_13_p
       else __windtrap_mut_13_p)
    then
      (if Windtrap_mut_________fixture_counter___ml.___windtrap_armed___ 11
       then ((())[@ocaml.warning "-41-42"])
       else
         if Windtrap_mut_________fixture_counter___ml.___windtrap_armed___ 12
         then decr r
         else incr r)
  let loaded = ref 0
  let () =
    if Windtrap_mut_________fixture_counter___ml.___windtrap_armed___ 14
    then decr loaded
    else incr loaded
  let dismissed r = ((incr r)[@mutate off "the count is a statistic"])
  let effectful f = incr (f ())
  let qualified r = Stdlib.incr r
  let piped r = r |> incr
  let applied r = incr @@ r
  let partial l = List.iter incr l
  let built () =
    incr
      {
        contents =
          (if Windtrap_mut_________fixture_counter___ml.___windtrap_armed___ 16
           then 1
           else 0)
      }
  type _ witness =
    | Ref: int ref witness 
  let gadt (type a) (w : a witness) (x : a) = incr (match w with | Ref -> x)

  $ mut --impl ./fixture_pos.ml | ../elide.exe
  mutation sites of "./fixture_pos.ml" in Windtrap_mut_________fixture_pos___ml, with type ints, type floats:
    0: 5:15-5:17 "pos" "- x" -> "x"
    1: 6:16-6:19 "pos" "-. x" -> "x"
    2: 7:18-7:22 "pos" "- (f x)" -> "f x"
    3: 8:15-8:23 "pos" "- x" -> "x"
    4: 12:14-12:19 "pos" "- (- x)" -> "- x"
    5: 13:14-13:20 "sub" "(- a) + b" -> "(- a) - b"
    6: 13:14-13:16 "pos" "- a" -> "a"
    7: 29:18-29:22 "pos" "- x" -> "x", dismissed "the sign is not checked"
    8: 35:16-35:22 "add" "x - (- y)" -> "x + (- y)"
    9: 36:15-36:31 "sub" "x + (- y : int)" -> "x - (- y : int)"
    10: 37:17-37:25 "fadd" "x -. (-. y)" -> "x +. (-. y)"
    11: 38:20-38:33 "pos" "- (- x : int)" -> "(- x : int)"
    12: 42:20-42:30 "add" "(a - (- b)) - c" -> "(a - (- b)) + c"
    13: 42:24-42:26 "pos" "- b" -> "b"
    14: 46:13-46:19 "pos" "- (!top)" -> "!top"
  let negate x =
    let __windtrap_mut_0_p : Stdlib.Int.t = x in
    if Windtrap_mut_________fixture_pos___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_p
    else - __windtrap_mut_0_p
  let fnegate x =
    let __windtrap_mut_1_p : Stdlib.Float.t = x in
    if Windtrap_mut_________fixture_pos___ml.___windtrap_armed___ 1
    then __windtrap_mut_1_p
    else -. __windtrap_mut_1_p
  let applied f x =
    let __windtrap_mut_2_p : Stdlib.Int.t = f x in
    if Windtrap_mut_________fixture_pos___ml.___windtrap_armed___ 2
    then __windtrap_mut_2_p
    else - __windtrap_mut_2_p
  let prefix x =
    let __windtrap_mut_3_p : Stdlib.Int.t = x in
    if Windtrap_mut_________fixture_pos___ml.___windtrap_armed___ 3
    then __windtrap_mut_3_p
    else - __windtrap_mut_3_p
  let twice x =
    let __windtrap_mut_4_p : Stdlib.Int.t = - x in
    if Windtrap_mut_________fixture_pos___ml.___windtrap_armed___ 4
    then __windtrap_mut_4_p
    else - __windtrap_mut_4_p
  let sum a b =
    let (__windtrap_mut_5_l, __windtrap_mut_5_r) =
      (((let __windtrap_mut_6_p : Stdlib.Int.t = a in
         if Windtrap_mut_________fixture_pos___ml.___windtrap_armed___ 6
         then __windtrap_mut_6_p
         else - __windtrap_mut_6_p), b) : Windtrap_mut_________fixture_pos___ml.ints) in
    if Windtrap_mut_________fixture_pos___ml.___windtrap_armed___ 5
    then __windtrap_mut_5_l - __windtrap_mut_5_r
    else __windtrap_mut_5_l + __windtrap_mut_5_r
  let one = (-1)
  let spaced = (-1)
  let bracketed = (-1)
  let fone = (-1.5)
  let partial l = List.map (~-) l
  let float_opened x = let open Float in - x
  let let_opened x = let open Counters in - x
  let dismissed x = ((- x)[@mutate off "the sign is not checked"])
  let logged x = Logs.debug (fun m -> m "%d" (- x))
  let minus x y =
    let (__windtrap_mut_8_l, __windtrap_mut_8_r) =
      ((x, (- y)) : Windtrap_mut_________fixture_pos___ml.ints) in
    if Windtrap_mut_________fixture_pos___ml.___windtrap_armed___ 8
    then __windtrap_mut_8_l + __windtrap_mut_8_r
    else __windtrap_mut_8_l - __windtrap_mut_8_r
  let plus x y =
    let (__windtrap_mut_9_l, __windtrap_mut_9_r) =
      ((x, (- y : int)) : Windtrap_mut_________fixture_pos___ml.ints) in
    if Windtrap_mut_________fixture_pos___ml.___windtrap_armed___ 9
    then __windtrap_mut_9_l - __windtrap_mut_9_r
    else __windtrap_mut_9_l + __windtrap_mut_9_r
  let fminus x y =
    let (__windtrap_mut_10_l, __windtrap_mut_10_r) =
      ((x, (-. y)) : Windtrap_mut_________fixture_pos___ml.floats) in
    if Windtrap_mut_________fixture_pos___ml.___windtrap_armed___ 10
    then __windtrap_mut_10_l +. __windtrap_mut_10_r
    else __windtrap_mut_10_l -. __windtrap_mut_10_r
  let constrained x =
    let __windtrap_mut_11_p : Stdlib.Int.t = (- x : int) in
    if Windtrap_mut_________fixture_pos___ml.___windtrap_armed___ 11
    then __windtrap_mut_11_p
    else - __windtrap_mut_11_p
  let chained a b c =
    let (__windtrap_mut_12_l, __windtrap_mut_12_r) =
      (((a -
           (let __windtrap_mut_13_p : Stdlib.Int.t = b in
            if Windtrap_mut_________fixture_pos___ml.___windtrap_armed___ 13
            then __windtrap_mut_13_p
            else - __windtrap_mut_13_p)), c) : Windtrap_mut_________fixture_pos___ml.ints) in
    if Windtrap_mut_________fixture_pos___ml.___windtrap_armed___ 12
    then __windtrap_mut_12_l + __windtrap_mut_12_r
    else __windtrap_mut_12_l - __windtrap_mut_12_r
  let top = ref 1
  let loaded =
    let __windtrap_mut_14_p : Stdlib.Int.t = !top in
    if Windtrap_mut_________fixture_pos___ml.___windtrap_armed___ 14
    then __windtrap_mut_14_p
    else - __windtrap_mut_14_p

  $ mut --impl ./fixture_left.ml | ../elide.exe
  mutation sites of "./fixture_left.ml" in Windtrap_mut_________fixture_left___ml, with type 'a lists:
    0: 4:17-4:22 "left" "a @ b" -> "a"
    1: 5:17-5:26 "left" "a @ b" -> "a"
    2: 9:24-9:35 "left" "(a @ b) @ c" -> "a @ b"
    3: 10:25-10:34 "left" "a @ (b @ c)" -> "a"
    4: 10:29-10:34 "left" "b @ c" -> "b"
    5: 15:23-15:28 "tail" "[x]" -> "[]"
    6: 16:21-16:29 "tail" "[x; y]" -> "[y]"
    7: 17:18-17:25 "left" "a @ b" -> "a"
    8: 17:28-17:33 "tail" "[x]" -> "[]"
    9: 18:17-18:29 "left" "a @ (x :: t)" -> "a"
    10: 18:21-18:29 "tail" "x :: t" -> "t"
    11: 19:14-19:20 "left" "[] @ b" -> "[]"
    12: 28:31-28:53 "tail" "x :: ([] : int list)" -> "([] : int list)"
    13: 32:10-32:21 "left" "base @ base" -> "base"
  let append a b =
    let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
      ((a, b) : _ Windtrap_mut_________fixture_left___ml.lists) in
    if Windtrap_mut_________fixture_left___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_l
    else __windtrap_mut_0_l @ __windtrap_mut_0_r
  let prefix a b =
    let (__windtrap_mut_1_l, __windtrap_mut_1_r) =
      ((a, b) : _ Windtrap_mut_________fixture_left___ml.lists) in
    if Windtrap_mut_________fixture_left___ml.___windtrap_armed___ 1
    then __windtrap_mut_1_l
    else __windtrap_mut_1_l @ __windtrap_mut_1_r
  let left_nested a b c =
    let (__windtrap_mut_2_l, __windtrap_mut_2_r) =
      (((a @ b), c) : _ Windtrap_mut_________fixture_left___ml.lists) in
    if Windtrap_mut_________fixture_left___ml.___windtrap_armed___ 2
    then __windtrap_mut_2_l
    else __windtrap_mut_2_l @ __windtrap_mut_2_r
  let right_nested a b c =
    let (__windtrap_mut_3_l, __windtrap_mut_3_r) =
      ((a,
         (let (__windtrap_mut_4_l, __windtrap_mut_4_r) =
            ((b, c) : _ Windtrap_mut_________fixture_left___ml.lists) in
          if Windtrap_mut_________fixture_left___ml.___windtrap_armed___ 4
          then __windtrap_mut_4_l
          else __windtrap_mut_4_l @ __windtrap_mut_4_r)) : _
                                                             Windtrap_mut_________fixture_left___ml.lists) in
    if Windtrap_mut_________fixture_left___ml.___windtrap_armed___ 3
    then __windtrap_mut_3_l
    else __windtrap_mut_3_l @ __windtrap_mut_3_r
  let empty a = a @ []
  let snoc acc x =
    acc @
      (if
         Stdlib.not
           (Windtrap_mut_________fixture_left___ml.___windtrap_armed___ 5)
       then [x]
       else [])
  let pair a x y =
    a @
      (if
         Stdlib.not
           (Windtrap_mut_________fixture_left___ml.___windtrap_armed___ 6)
       then [x; y]
       else [y])
  let inner a b x =
    (let (__windtrap_mut_7_l, __windtrap_mut_7_r) =
       ((a, b) : _ Windtrap_mut_________fixture_left___ml.lists) in
     if Windtrap_mut_________fixture_left___ml.___windtrap_armed___ 7
     then __windtrap_mut_7_l
     else __windtrap_mut_7_l @ __windtrap_mut_7_r) @
      (if
         Stdlib.not
           (Windtrap_mut_________fixture_left___ml.___windtrap_armed___ 8)
       then [x]
       else [])
  let cons a x t =
    let (__windtrap_mut_9_l, __windtrap_mut_9_r) =
      ((a,
         (if
            Stdlib.not
              (Windtrap_mut_________fixture_left___ml.___windtrap_armed___ 10)
          then x :: t
          else t)) : _ Windtrap_mut_________fixture_left___ml.lists) in
    if Windtrap_mut_________fixture_left___ml.___windtrap_armed___ 9
    then __windtrap_mut_9_l
    else __windtrap_mut_9_l @ __windtrap_mut_9_r
  let first b =
    let (__windtrap_mut_11_l, __windtrap_mut_11_r) =
      (([], b) : _ Windtrap_mut_________fixture_left___ml.lists) in
    if Windtrap_mut_________fixture_left___ml.___windtrap_armed___ 11
    then __windtrap_mut_11_l
    else __windtrap_mut_11_l @ __windtrap_mut_11_r
  let opened a b = let open List in a @ b
  let qualified a b = Stdlib.(@) a b
  let partial a = List.map ((@) a)
  let constrained a = a @ ([] : int list)
  let constrained_tail a x =
    a @
      (if
         Stdlib.not
           (Windtrap_mut_________fixture_left___ml.___windtrap_armed___ 12)
       then x :: ([] : int list)
       else ([] : int list))
  let base = [1]
  let all =
    let (__windtrap_mut_13_l, __windtrap_mut_13_r) =
      ((base, base) : _ Windtrap_mut_________fixture_left___ml.lists) in
    if Windtrap_mut_________fixture_left___ml.___windtrap_armed___ 13
    then __windtrap_mut_13_l
    else __windtrap_mut_13_l @ __windtrap_mut_13_r

  $ mut --impl ./fixture_del.ml | ../elide.exe
  mutation sites of "./fixture_del.ml" in Windtrap_mut_________fixture_del___ml:
    0: 8:2-8:18 "del" "log := (x :: (!log))" -> "()"
    1: 8:9-8:18 "tail" "x :: (!log)" -> "!log"
    2: 12:10-12:11 "int" "1" -> "0"
    3: 13:4-13:15 "del" "print_int i" -> "()"
    4: 14:4-14:20 "del" "print_newline ()" -> "()"
    5: 26:2-26:62 "del" "print_string \"x\"" -> "()", dismissed "the output is not checked"
    6: 31:2-31:8 "del" "a || b" -> "()"
    7: 31:2-31:8 "and" "a || b" -> "a && b"
    8: 41:2-41:25 "del" "output_string oc \"done\"" -> "()"
  let log = ref []
  let push x =
    (if Windtrap_mut_________fixture_del___ml.___windtrap_armed___ 0
     then ((())[@ocaml.warning "-41-42"])
     else
       (log :=
          (if
             Stdlib.not
               (Windtrap_mut_________fixture_del___ml.___windtrap_armed___ 1)
           then x :: (!log)
           else !log);
        ((())
        [@ocaml.warning "-41-42"])) : Stdlib.Unit.t);
    List.length (!log)
  let loop n =
    for i =
      if Windtrap_mut_________fixture_del___ml.___windtrap_armed___ 2
      then 0
      else 1 to n do
      (if Windtrap_mut_________fixture_del___ml.___windtrap_armed___ 3
       then ((())[@ocaml.warning "-41-42"])
       else (print_int i; ((())[@ocaml.warning "-41-42"])) : Stdlib.Unit.t);
      (if Windtrap_mut_________fixture_del___ml.___windtrap_armed___ 4
       then ((())[@ocaml.warning "-41-42"])
       else (print_newline (); ((())[@ocaml.warning "-41-42"])) : Stdlib.Unit.t)
    done
  let unit_first x = (); x
  let checked x = assert (x > 0); x
  let quiet x =
    ((print_string "x")[@mutate off "the output is not checked"]); x
  let either a b =
    (if Windtrap_mut_________fixture_del___ml.___windtrap_armed___ 6
     then ((())[@ocaml.warning "-41-42"])
     else
       ((let __windtrap_mut_7_p : Stdlib.Bool.t = a in
         (if
            Stdlib.(=) __windtrap_mut_7_p
              (Windtrap_mut_________fixture_del___ml.___windtrap_armed___ 7)
          then b
          else __windtrap_mut_7_p : Stdlib.Bool.t));
        ((())
        [@ocaml.warning "-41-42"])) : Stdlib.Unit.t);
    ()
  let () = print_string "loaded"; print_newline ()
  let finish oc ic fd dir =
    (if Windtrap_mut_________fixture_del___ml.___windtrap_armed___ 8
     then ((())[@ocaml.warning "-41-42"])
     else (output_string oc "done"; ((())[@ocaml.warning "-41-42"])) : 
    Stdlib.Unit.t);
    close_out oc;
    close_in_noerr ic;
    (try Unix.close fd with | Unix.Unix_error _ -> ());
    ignore (Unix.closedir dir);
    flush stdout

A then-branch with no else, a loop body and the last statement of a
sequence there are statements too. The guard of a then-branch keeps the
branch in tail position:

  $ mut --impl ./fixture_del_units.ml | ../elide.exe
  mutation sites of "./fixture_del_units.ml" in Windtrap_mut_________fixture_del_units___ml, with type 'a operands, type ints:
    0: 6:29-6:39 "del" "incr count" -> "()"
    1: 6:29-6:39 "decr" "incr count" -> "decr count"
    2: 6:19-6:23 "not" "flag" -> "not flag"
    3: 12:4-12:14 "del" "incr count" -> "()"
    4: 12:4-12:14 "decr" "incr count" -> "decr count"
    5: 13:4-13:20 "del" "print_int (!count)" -> "()"
    6: 14:4-14:20 "del" "print_newline ()" -> "()"
    7: 11:5-11:9 "not" "flag" -> "not flag"
    8: 18:4-18:16 "del" "decr pending" -> "()"
    9: 18:4-18:16 "incr" "decr pending" -> "incr pending"
    10: 17:8-17:20 "ge" "(!pending) > 0" -> "(!pending) >= 0"
    11: 17:19-17:20 "int" "0" -> "1"
    12: 23:4-23:22 "del" "print_int (!pending)" -> "()"
    13: 24:4-24:16 "del" "decr pending" -> "()"
    14: 24:4-24:16 "incr" "decr pending" -> "incr pending"
    15: 22:8-22:20 "ge" "(!pending) > 0" -> "(!pending) >= 0"
    16: 22:19-22:20 "int" "0" -> "1"
    17: 28:10-28:11 "int" "1" -> "0"
    18: 29:4-29:15 "del" "print_int i" -> "()"
    19: 33:19-33:20 "int" "1" -> "0"
    20: 34:4-34:15 "del" "print_int i" -> "()"
    21: 35:4-35:20 "del" "print_newline ()" -> "()"
    22: 40:10-40:11 "int" "1" -> "0"
    23: 41:4-41:10 "del" "!count" -> "()"
    24: 45:36-45:53 "del" "countdown (n - 1)" -> "()"
    25: 45:46-45:53 "add" "n - 1" -> "n + 1"
    26: 45:25-45:30 "ge" "n > 0" -> "n >= 0"
    27: 45:29-45:30 "int" "0" -> "1"
    28: 48:21-48:25 "not" "flag" -> "not flag"
    29: 51:22-51:26 "not" "flag" -> "not flag"
    30: 52:22-52:26 "not" "flag" -> "not flag"
    31: 53:24-53:28 "not" "flag" -> "not flag"
    32: 56:8-56:15 "not" "more ()" -> "not (more ())"
    33: 61:12-61:30 "ge" "Sys.word_size > 32" -> "Sys.word_size >= 32"
    34: 70:15-70:75 "del" "print_string \"x\"" -> "()", dismissed "the output is not checked"
    35: 70:5-70:9 "not" "flag" -> "not flag"
    36: 74:4-74:14 "del" "incr count" -> "()"
    37: 74:4-74:14 "decr" "incr count" -> "decr count"
    38: 75:4-75:64 "del" "print_string \"x\"" -> "()", dismissed "the output is not checked"
    39: 73:5-73:9 "not" "flag" -> "not flag"
    40: 80:8-80:15 "not" "more ()" -> "not (more ())"
    41: 86:4-86:14 "del" "incr count" -> "()"
    42: 86:4-86:14 "decr" "incr count" -> "decr count"
    43: 85:5-85:9 "not" "flag" -> "not flag"
    44: 90:10-90:11 "int" "1" -> "0"
  let count = ref 0
  let bump flag =
    if
      let __windtrap_mut_2_p : Stdlib.Bool.t = flag in
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 2
       then Stdlib.not __windtrap_mut_2_p
       else __windtrap_mut_2_p)
    then
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 0
       then ((())[@ocaml.warning "-41-42"])
       else
         if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 1
         then decr count
         else incr count)
  let both flag =
    if
      let __windtrap_mut_7_p : Stdlib.Bool.t = flag in
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 7
       then Stdlib.not __windtrap_mut_7_p
       else __windtrap_mut_7_p)
    then
      ((if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 3
        then ((())[@ocaml.warning "-41-42"])
        else
          (if
             Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 4
           then decr count
           else incr count;
           ((())
           [@ocaml.warning "-41-42"])) : Stdlib.Unit.t);
       (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 5
        then ((())[@ocaml.warning "-41-42"])
        else (print_int (!count); ((())[@ocaml.warning "-41-42"])) : Stdlib.Unit.t);
       if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 6
       then ((())[@ocaml.warning "-41-42"])
       else print_newline ())
  let drain pending =
    while
      let (__windtrap_mut_10_l, __windtrap_mut_10_r) =
        (((!pending),
           (if
              Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___
                11
            then 1
            else 0)) : _ Windtrap_mut_________fixture_del_units___ml.operands) in
      if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 10
      then Stdlib.not (__windtrap_mut_10_r > __windtrap_mut_10_l)
      else __windtrap_mut_10_l > __windtrap_mut_10_r do
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 8
       then ((())[@ocaml.warning "-41-42"])
       else
         (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 9
          then incr pending
          else decr pending;
          ((())
          [@ocaml.warning "-41-42"])) : Stdlib.Unit.t)
      done
  let drain_noisy pending =
    while
      let (__windtrap_mut_15_l, __windtrap_mut_15_r) =
        (((!pending),
           (if
              Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___
                16
            then 1
            else 0)) : _ Windtrap_mut_________fixture_del_units___ml.operands) in
      if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 15
      then Stdlib.not (__windtrap_mut_15_r > __windtrap_mut_15_l)
      else __windtrap_mut_15_l > __windtrap_mut_15_r do
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 12
       then ((())[@ocaml.warning "-41-42"])
       else (print_int (!pending); ((())[@ocaml.warning "-41-42"])) : Stdlib.Unit.t);
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 13
       then ((())[@ocaml.warning "-41-42"])
       else
         (if
            Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 14
          then incr pending
          else decr pending;
          ((())
          [@ocaml.warning "-41-42"])) : Stdlib.Unit.t)
      done
  let up n =
    for i =
      if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 17
      then 0
      else 1 to n do
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 18
       then ((())[@ocaml.warning "-41-42"])
       else (print_int i; ((())[@ocaml.warning "-41-42"])) : Stdlib.Unit.t)
    done
  let down n =
    for i = n downto
      if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 19
      then 0
      else 1 do
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 20
       then ((())[@ocaml.warning "-41-42"])
       else (print_int i; ((())[@ocaml.warning "-41-42"])) : Stdlib.Unit.t);
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 21
       then ((())[@ocaml.warning "-41-42"])
       else (print_newline (); ((())[@ocaml.warning "-41-42"])) : Stdlib.Unit.t)
    done
  let peek n =
    for _ =
      if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 22
      then 0
      else 1 to n do
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 23
       then ((())[@ocaml.warning "-41-42"])
       else (!count; ((())[@ocaml.warning "-41-42"])) : Stdlib.Unit.t)
    done
  let rec countdown n =
    if
      let (__windtrap_mut_26_l, __windtrap_mut_26_r) =
        ((n,
           (if
              Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___
                27
            then 1
            else 0)) : _ Windtrap_mut_________fixture_del_units___ml.operands) in
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 26
       then Stdlib.not (__windtrap_mut_26_r > __windtrap_mut_26_l)
       else __windtrap_mut_26_l > __windtrap_mut_26_r)
    then
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 24
       then ((())[@ocaml.warning "-41-42"])
       else
         countdown
           (let (__windtrap_mut_25_l, __windtrap_mut_25_r) =
              ((n, 1) : Windtrap_mut_________fixture_del_units___ml.ints) in
            if
              Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___
                25
            then __windtrap_mut_25_l + __windtrap_mut_25_r
            else __windtrap_mut_25_l - __windtrap_mut_25_r))
  let either flag =
    if
      let __windtrap_mut_28_p : Stdlib.Bool.t = flag in
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 28
       then Stdlib.not __windtrap_mut_28_p
       else __windtrap_mut_28_p)
    then print_string "a"
    else print_string "b"
  let nothing flag =
    if
      let __windtrap_mut_29_p : Stdlib.Bool.t = flag in
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 29
       then Stdlib.not __windtrap_mut_29_p
       else __windtrap_mut_29_p)
    then ()
  let checked flag =
    if
      let __windtrap_mut_30_p : Stdlib.Bool.t = flag in
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 30
       then Stdlib.not __windtrap_mut_30_p
       else __windtrap_mut_30_p)
    then assert false
  let finish flag oc =
    if
      let __windtrap_mut_31_p : Stdlib.Bool.t = flag in
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 31
       then Stdlib.not __windtrap_mut_31_p
       else __windtrap_mut_31_p)
    then close_out oc
  let finish_all more next =
    while
      let __windtrap_mut_32_p : Stdlib.Bool.t = more () in
      if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 32
      then Stdlib.not __windtrap_mut_32_p
      else __windtrap_mut_32_p do close_in (next ()) done
  let () =
    if
      let (__windtrap_mut_33_l, __windtrap_mut_33_r) =
        ((Sys.word_size, 32) : _
                                 Windtrap_mut_________fixture_del_units___ml.operands) in
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 33
       then Stdlib.not (__windtrap_mut_33_r > __windtrap_mut_33_l)
       else __windtrap_mut_33_l > __windtrap_mut_33_r)
    then print_string "loaded"
  let () = for _ = 1 to 2 do print_string "loaded" done
  let quiet flag =
    if
      let __windtrap_mut_35_p : Stdlib.Bool.t = flag in
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 35
       then Stdlib.not __windtrap_mut_35_p
       else __windtrap_mut_35_p)
    then ((print_string "x")[@mutate off "the output is not checked"])
  let quiet_last flag =
    if
      let __windtrap_mut_39_p : Stdlib.Bool.t = flag in
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 39
       then Stdlib.not __windtrap_mut_39_p
       else __windtrap_mut_39_p)
    then
      ((if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 36
        then ((())[@ocaml.warning "-41-42"])
        else
          (if
             Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___
               37
           then decr count
           else incr count;
           ((())
           [@ocaml.warning "-41-42"])) : Stdlib.Unit.t);
       ((print_string "x")
       [@mutate off "the output is not checked"]))
  let idle more =
    while
      let __windtrap_mut_40_p : Stdlib.Bool.t = more () in
      if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 40
      then Stdlib.not __windtrap_mut_40_p
      else __windtrap_mut_40_p do () done
  let bump_only flag =
    if
      let __windtrap_mut_43_p : Stdlib.Bool.t = flag in
      (if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 43
       then Stdlib.not __windtrap_mut_43_p
       else __windtrap_mut_43_p)
    then
      ((if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 41
        then ((())[@ocaml.warning "-41-42"])
        else
          (if
             Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___
               42
           then decr count
           else incr count;
           ((())
           [@ocaml.warning "-41-42"])) : Stdlib.Unit.t);
       ())
  let deferred n =
    for _ =
      if Windtrap_mut_________fixture_del_units___ml.___windtrap_armed___ 44
      then 0
      else 1 to n do
      lazy count
    done

  $ mut --impl ./fixture_literals.ml | ../elide.exe
  mutation sites of "./fixture_literals.ml" in Windtrap_mut_________fixture_literals___ml, with type 'a operands, type ints:
    0: 4:30-4:31 "int" "1" -> "0"
    1: 4:23-4:24 "int" "7" -> "8"
    2: 4:16-4:17 "not" "b" -> "not b"
    3: 5:19-5:21 "int" "1l" -> "0l"
    4: 5:23-5:25 "int" "2L" -> "3L"
    5: 5:27-5:29 "int" "3n" -> "4n"
    6: 5:31-5:35 "int" "0x10" -> "17"
    7: 5:37-5:39 "int" "(-5)" -> "(-4)"
    8: 5:41-5:46 "int" "1_000" -> "1001"
    9: 9:15-9:19 "bool" "true" -> "false"
    10: 9:21-9:31 "or" "x && false" -> "x || false"
    11: 9:53-9:58 "bool" "false" -> "true"
    12: 9:36-9:40 "not" "true" -> "not true"
    13: 13:13-13:18 "sub" "x + 1" -> "x - 1"
    14: 14:13-14:18 "add" "1 - x" -> "1 + x"
    15: 16:35-16:36 "int" "3" -> "4"
    16: 16:28-16:29 "int" "2" -> "3"
    17: 16:17-16:22 "le" "x < 0" -> "x <= 0"
    18: 17:38-17:39 "int" "5" -> "6"
    19: 17:31-17:32 "int" "4" -> "5"
    20: 17:19-17:25 "lt" "x <= 1" -> "x < 1"
    21: 18:35-18:36 "int" "8" -> "9"
    22: 18:28-18:29 "int" "6" -> "7"
    23: 18:17-18:22 "ge" "x > 1" -> "x >= 1"
    24: 19:39-19:41 "int" "10" -> "11"
    25: 19:32-19:33 "int" "9" -> "10"
    26: 19:20-19:26 "gt" "x >= 1" -> "x > 1"
    27: 19:25-19:26 "int" "1" -> "0"
    28: 20:39-20:41 "int" "12" -> "13"
    29: 20:31-20:33 "int" "11" -> "12"
    30: 20:20-20:25 "le" "0 < x" -> "0 <= x"
    31: 20:20-20:21 "int" "0" -> "1"
    32: 23:18-23:20 "int" "65" -> "66"
    33: 26:13-26:15 "int" "66" -> "67"
    34: 31:20-31:22 "int" "67" -> "68"
  let pick b =
    if
      let __windtrap_mut_2_p : Stdlib.Bool.t = b in
      (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 2
       then Stdlib.not __windtrap_mut_2_p
       else __windtrap_mut_2_p)
    then
      (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 1
       then 8
       else 7)
    else
      if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 0
      then 0
      else 1
  let suffixed () =
    ((if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 3
      then 0l
      else 1l),
      (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 4
       then 3L
       else 2L),
      (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 5
       then 4n
       else 3n),
      (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 6
       then 17
       else 0x10),
      (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 7
       then (-4)
       else (-5)),
      (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 8
       then 1001
       else 1_000))
  let edges () = (max_int, 4611686018427387903, 9223372036854775807L, 4z)
  let flags x =
    ((if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 9
      then false
      else true),
      (let __windtrap_mut_10_p : Stdlib.Bool.t = x in
       (if
          Stdlib.(<>) __windtrap_mut_10_p
            (Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 10)
        then false
        else __windtrap_mut_10_p : Stdlib.Bool.t)),
      (if
         let __windtrap_mut_12_p : Stdlib.Bool.t = true in
         (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 12
          then Stdlib.not __windtrap_mut_12_p
          else __windtrap_mut_12_p)
       then x
       else
         if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 11
         then true
         else false))
  let succ x =
    let (__windtrap_mut_13_l, __windtrap_mut_13_r) =
      ((x, 1) : Windtrap_mut_________fixture_literals___ml.ints) in
    if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 13
    then __windtrap_mut_13_l - __windtrap_mut_13_r
    else __windtrap_mut_13_l + __windtrap_mut_13_r
  let pred x =
    let (__windtrap_mut_14_l, __windtrap_mut_14_r) =
      ((1, x) : Windtrap_mut_________fixture_literals___ml.ints) in
    if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 14
    then __windtrap_mut_14_l + __windtrap_mut_14_r
    else __windtrap_mut_14_l - __windtrap_mut_14_r
  let table () = Hashtbl.create 16
  let below x =
    if
      let (__windtrap_mut_17_l, __windtrap_mut_17_r) =
        ((x, 0) : _ Windtrap_mut_________fixture_literals___ml.operands) in
      (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 17
       then Stdlib.not (__windtrap_mut_17_r < __windtrap_mut_17_l)
       else __windtrap_mut_17_l < __windtrap_mut_17_r)
    then
      (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 16
       then 3
       else 2)
    else
      if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 15
      then 4
      else 3
  let at_most x =
    if
      let (__windtrap_mut_20_l, __windtrap_mut_20_r) =
        ((x, 1) : _ Windtrap_mut_________fixture_literals___ml.operands) in
      (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 20
       then Stdlib.not (__windtrap_mut_20_r <= __windtrap_mut_20_l)
       else __windtrap_mut_20_l <= __windtrap_mut_20_r)
    then
      (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 19
       then 5
       else 4)
    else
      if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 18
      then 6
      else 5
  let above x =
    if
      let (__windtrap_mut_23_l, __windtrap_mut_23_r) =
        ((x, 1) : _ Windtrap_mut_________fixture_literals___ml.operands) in
      (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 23
       then Stdlib.not (__windtrap_mut_23_r > __windtrap_mut_23_l)
       else __windtrap_mut_23_l > __windtrap_mut_23_r)
    then
      (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 22
       then 7
       else 6)
    else
      if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 21
      then 9
      else 8
  let at_least x =
    if
      let (__windtrap_mut_26_l, __windtrap_mut_26_r) =
        ((x,
           (if
              Windtrap_mut_________fixture_literals___ml.___windtrap_armed___
                27
            then 0
            else 1)) : _ Windtrap_mut_________fixture_literals___ml.operands) in
      (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 26
       then Stdlib.not (__windtrap_mut_26_r >= __windtrap_mut_26_l)
       else __windtrap_mut_26_l >= __windtrap_mut_26_r)
    then
      (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 25
       then 10
       else 9)
    else
      if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 24
      then 11
      else 10
  let mirrored x =
    if
      let (__windtrap_mut_30_l, __windtrap_mut_30_r) =
        (((if
             Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 31
           then 1
           else 0), x) : _ Windtrap_mut_________fixture_literals___ml.operands) in
      (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 30
       then Stdlib.not (__windtrap_mut_30_r < __windtrap_mut_30_l)
       else __windtrap_mut_30_l < __windtrap_mut_30_r)
    then
      (if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 29
       then 12
       else 11)
    else
      if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 28
      then 13
      else 12
  let limit = 64
  let verbose = false
  let later =
    lazy
      ((if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 32
        then 66
        else 65), ())
  module Make(X:sig  end) =
    struct
      let size =
        if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 33
        then 67
        else 66
    end
  class counter =
    object
      val mutable n =
        if Windtrap_mut_________fixture_literals___ml.___windtrap_armed___ 34
        then 68
        else 67
      method get = n
    end
  let pipe () = Unix.pipe ~cloexec:true ()

  $ mut --impl ./fixture_ret.ml | ../elide.exe
  mutation sites of "./fixture_ret.ml" in Windtrap_mut_________fixture_ret___ml, with type ints:
    0: 5:13-5:25 "none" "Some (x + 1)" -> "None"
    1: 5:18-5:25 "sub" "x + 1" -> "x - 1"
    2: 6:16-6:23 "tail" "x :: xs" -> "xs"
    3: 7:15-7:26 "tail" "[1; 2; 3]" -> "[2; 3]"
    4: 7:17-7:18 "int" "1" -> "0"
    5: 7:20-7:21 "int" "2" -> "3"
    6: 7:23-7:24 "int" "3" -> "4"
    7: 8:15-8:25 "tail" "[x; y]" -> "[y]"
    8: 11:2-12:9 "tail" "[\"a\"; \"b\"]" -> "[\"b\"]"
    9: 15:18-15:29 "tail" "a :: b :: t" -> "b :: t"
    10: 21:17-21:18 "int" "1" -> "0"
    11: 22:24-22:48 "tail" "1 :: (Lazy.force stream)" -> "Lazy.force stream"
    12: 22:25-22:26 "int" "1" -> "0"
    13: 23:42-23:60 "tail" "n :: (count (n - 1))" -> "count (n - 1)"
    14: 23:53-23:60 "add" "n - 1" -> "n + 1"
    15: 23:23-23:28 "neq" "n = 0" -> "n <> 0"
    16: 23:27-23:28 "int" "0" -> "1"
    17: 27:17-27:18 "int" "1" -> "0"
    18: 33:17-33:18 "int" "1" -> "0"
    19: 34:13-34:18 "tail" "[2]" -> "[]"
    20: 34:15-34:16 "int" "2" -> "3"
  let wrap x =
    if
      Stdlib.not (Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 0)
    then
      Some
        (let (__windtrap_mut_1_l, __windtrap_mut_1_r) =
           ((x, 1) : Windtrap_mut_________fixture_ret___ml.ints) in
         (if Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 1
          then __windtrap_mut_1_l - __windtrap_mut_1_r
          else __windtrap_mut_1_l + __windtrap_mut_1_r))
    else ((None)[@ocaml.warning "-18-41-42"])
  let push x xs =
    if
      Stdlib.not (Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 2)
    then x :: xs
    else xs
  let three () =
    if
      Stdlib.not (Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 3)
    then
      [(if Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 4
        then 0
        else 1);
      (if Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 5
       then 3
       else 2);
      (if Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 6
       then 4
       else 3)]
    else [2; 3]
  let pair x y =
    if
      Stdlib.not (Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 7)
    then [x; y]
    else [y]
  let long () =
    if
      Stdlib.not (Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 8)
    then ["a"; "b"]
    else ["b"]
  let chain a b t =
    if
      Stdlib.not (Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 9)
    then a :: b :: t
    else b :: t
  let local () =
    let rec ones =
      (if Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 10
       then 0
       else 1)
      :: ones in
    let rec stream =
      lazy
        (if
           Stdlib.not
             (Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 11)
         then
           ((if Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 12
             then 0
             else 1))
           :: (Lazy.force stream)
         else Lazy.force stream) in
    let rec count n =
      if
        let __windtrap_mut_15_p : Stdlib.Bool.t =
          n =
            (if Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 16
             then 1
             else 0) in
        (if Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 15
         then Stdlib.not __windtrap_mut_15_p
         else __windtrap_mut_15_p)
      then []
      else
        if
          Stdlib.not
            (Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 13)
        then n ::
          (count
             (let (__windtrap_mut_14_l, __windtrap_mut_14_r) =
                ((n, 1) : Windtrap_mut_________fixture_ret___ml.ints) in
              if Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 14
              then __windtrap_mut_14_l + __windtrap_mut_14_r
              else __windtrap_mut_14_l - __windtrap_mut_14_r))
        else count (n - 1) in
    (ones, stream, count)
  class cycle =
    let rec ones =
      (if Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 17
       then 0
       else 1)
      :: ones
    in object method ones = ones end
  module Make(X:sig  end) =
    struct
      let rec ones =
        (if Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 18
         then 0
         else 1)
        :: ones
      let twos =
        if
          Stdlib.not
            (Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 19)
        then
          [(if Windtrap_mut_________fixture_ret___ml.___windtrap_armed___ 20
            then 3
            else 2)]
        else []
    end
  let first = Some 1
  let rest = [1; 2]
  let qualified x = Option.Some x
  let empty () = (None, [])

  $ mut --impl ./fixture_ret_edges.ml | ../elide.exe
  mutation sites of "./fixture_ret_edges.ml" in Windtrap_mut_________fixture_ret_edges___ml:
    0: 3:18-3:79 "tail" "x :: (match y with | Some z -> [z])" -> "match y with | Some z -> [z]"
    1: 3:49-3:54 "tail" "[z]" -> "[]"
    2: 4:17-4:74 "tail" "[x; (match y with | Some z -> z)]" -> "[(match y with | Some z -> z)]"
    3: 10:24-10:41 "tail" "(x :: cur) :: acc" -> "acc"
    4: 11:19-11:31 "tail" "[x] :: acc" -> "acc"
    5: 12:21-12:38 "tail" "y :: [x] :: acc" -> "[x] :: acc"
    6: 12:26-12:31 "tail" "[x]" -> "[]"
    7: 13:17-13:33 "tail" "[[x]; [y]]" -> "[[y]]"
    8: 13:19-13:24 "tail" "[x]" -> "[]"
    9: 13:26-13:31 "tail" "[y]" -> "[]"
  let partial x y =
    if
      Stdlib.not
        (Windtrap_mut_________fixture_ret_edges___ml.___windtrap_armed___ 0)
    then ((x ::
      (match y with
       | Some z ->
           (if
              Stdlib.not
                (Windtrap_mut_________fixture_ret_edges___ml.___windtrap_armed___
                   1)
            then [z]
            else [])))
      [@ocaml.warning "-8"])
    else (((match y with | Some z -> [z]))[@ocaml.warning "-8"])
  let listed x y =
    if
      Stdlib.not
        (Windtrap_mut_________fixture_ret_edges___ml.___windtrap_armed___ 2)
    then (([x; (match y with | Some z -> z)])[@ocaml.warning "-8"])
    else (([(match y with | Some z -> z)])[@ocaml.warning "-8"])
  let grouped x cur acc =
    if
      Stdlib.not
        (Windtrap_mut_________fixture_ret_edges___ml.___windtrap_armed___ 3)
    then (x :: cur) :: acc
    else acc
  let single x acc =
    if
      Stdlib.not
        (Windtrap_mut_________fixture_ret_edges___ml.___windtrap_armed___ 4)
    then [x] :: acc
    else acc
  let middle x y acc =
    if
      Stdlib.not
        (Windtrap_mut_________fixture_ret_edges___ml.___windtrap_armed___ 5)
    then y ::
      ((if
          Stdlib.not
            (Windtrap_mut_________fixture_ret_edges___ml.___windtrap_armed___ 6)
        then [x]
        else []))
      :: acc
    else [x] :: acc
  let nested x y =
    if
      Stdlib.not
        (Windtrap_mut_________fixture_ret_edges___ml.___windtrap_armed___ 7)
    then
      [(if
          Stdlib.not
            (Windtrap_mut_________fixture_ret_edges___ml.___windtrap_armed___ 8)
        then [x]
        else []);
      (if
         Stdlib.not
           (Windtrap_mut_________fixture_ret_edges___ml.___windtrap_armed___ 9)
       then [y]
       else [])]
    else [[y]]

  $ mut --impl ./fixture_assert.ml | ../elide.exe
  mutation sites of "./fixture_assert.ml" in Windtrap_mut_________fixture_assert___ml, with type 'a operands, type ints:
    0: 7:2-7:7 "sub" "a + b" -> "a - b"
    1: 16:50-16:51 "int" "0" -> "1"
    2: 16:43-16:44 "int" "1" -> "0"
    3: 17:21-17:42 "or" "(a < b) && (assert false)" -> "(a < b) || (assert false)"
    4: 17:21-17:26 "le" "a < b" -> "a <= b"
    5: 28:7-28:8 "int" "0" -> "1"
    6: 27:7-27:8 "int" "1" -> "0"
    7: 25:4-26:9 "not" "assert (a < b); a > b" -> "not (assert (a < b); a > b)"
  let checked a b =
    assert (a < b);
    (let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
       ((a, b) : Windtrap_mut_________fixture_assert___ml.ints) in
     if Windtrap_mut_________fixture_assert___ml.___windtrap_armed___ 0
     then __windtrap_mut_0_l - __windtrap_mut_0_r
     else __windtrap_mut_0_l + __windtrap_mut_0_r)
  let conjunction a b = assert (a && b)
  let arithmetic a b = assert ((a + b) > 0)
  let as_condition () =
    if assert false
    then
      (if Windtrap_mut_________fixture_assert___ml.___windtrap_armed___ 2
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_assert___ml.___windtrap_armed___ 1
      then 1
      else 0
  let as_operand a b =
    let __windtrap_mut_3_p : Stdlib.Bool.t =
      let (__windtrap_mut_4_l, __windtrap_mut_4_r) =
        ((a, b) : _ Windtrap_mut_________fixture_assert___ml.operands) in
      if Windtrap_mut_________fixture_assert___ml.___windtrap_armed___ 4
      then Stdlib.not (__windtrap_mut_4_r < __windtrap_mut_4_l)
      else __windtrap_mut_4_l < __windtrap_mut_4_r in
    (if
       Stdlib.(<>) __windtrap_mut_3_p
         (Windtrap_mut_________fixture_assert___ml.___windtrap_armed___ 3)
     then assert false
     else __windtrap_mut_3_p : Stdlib.Bool.t)
  let sequenced a b =
    if
      let __windtrap_mut_7_p : Stdlib.Bool.t = assert (a < b); a > b in
      (if Windtrap_mut_________fixture_assert___ml.___windtrap_armed___ 7
       then Stdlib.not __windtrap_mut_7_p
       else __windtrap_mut_7_p)
    then
      (if Windtrap_mut_________fixture_assert___ml.___windtrap_armed___ 6
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_assert___ml.___windtrap_armed___ 5
      then 1
      else 0

  $ mut --impl ./fixture_chain.ml | ../elide.exe
  mutation sites of "./fixture_chain.ml" in Windtrap_mut_________fixture_chain___ml, with type 'a operands, type ints, type floats:
    0: 19:18-19:27 "sub" "(a + b) + c" -> "(a + b) - c"
    1: 20:18-20:27 "add" "(a - b) - c" -> "(a - b) + c"
    2: 21:19-21:30 "fsub" "(a +. b) +. c" -> "(a +. b) -. c"
    3: 22:44-22:45 "int" "0" -> "1"
    4: 22:37-22:38 "int" "1" -> "0"
    5: 22:25-22:31 "or" "b && c" -> "b || c"
    6: 31:26-31:37 "sub" "(a + b) + c" -> "(a + b) - c"
    7: 32:23-32:34 "sub" "(a + b) + c" -> "(a + b) - c"
    8: 33:31-33:37 "or" "b && c" -> "b || c"
    9: 39:23-39:38 "sub" "(a + b) + (c + d)" -> "(a + b) - (c + d)"
    10: 39:31-39:38 "sub" "c + d" -> "c - d"
    11: 43:18-43:27 "add" "(a + b) - c" -> "(a + b) + c"
    12: 43:18-43:23 "sub" "a + b" -> "a - b"
    13: 48:45-48:46 "int" "0" -> "1"
    14: 48:38-48:39 "int" "1" -> "0"
    15: 48:23-48:32 "le" "(a < b) < c" -> "(a < b) <= c"
  let three a b c =
    let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
      (((a + b), c) : Windtrap_mut_________fixture_chain___ml.ints) in
    if Windtrap_mut_________fixture_chain___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_l - __windtrap_mut_0_r
    else __windtrap_mut_0_l + __windtrap_mut_0_r
  let minus a b c =
    let (__windtrap_mut_1_l, __windtrap_mut_1_r) =
      (((a - b), c) : Windtrap_mut_________fixture_chain___ml.ints) in
    if Windtrap_mut_________fixture_chain___ml.___windtrap_armed___ 1
    then __windtrap_mut_1_l + __windtrap_mut_1_r
    else __windtrap_mut_1_l - __windtrap_mut_1_r
  let floats a b c =
    let (__windtrap_mut_2_l, __windtrap_mut_2_r) =
      (((a +. b), c) : Windtrap_mut_________fixture_chain___ml.floats) in
    if Windtrap_mut_________fixture_chain___ml.___windtrap_armed___ 2
    then __windtrap_mut_2_l -. __windtrap_mut_2_r
    else __windtrap_mut_2_l +. __windtrap_mut_2_r
  let conn a b c =
    if
      a &&
        (let __windtrap_mut_5_p : Stdlib.Bool.t = b in
         ((if
             Stdlib.(<>) __windtrap_mut_5_p
               (Windtrap_mut_________fixture_chain___ml.___windtrap_armed___ 5)
           then c
           else __windtrap_mut_5_p) : Stdlib.Bool.t))
    then
      (if Windtrap_mut_________fixture_chain___ml.___windtrap_armed___ 4
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_chain___ml.___windtrap_armed___ 3
      then 1
      else 0
  let parens a b c =
    ignore
      (let (__windtrap_mut_6_l, __windtrap_mut_6_r) =
         (((a + b), c) : Windtrap_mut_________fixture_chain___ml.ints) in
       if Windtrap_mut_________fixture_chain___ml.___windtrap_armed___ 6
       then __windtrap_mut_6_l - __windtrap_mut_6_r
       else __windtrap_mut_6_l + __windtrap_mut_6_r)
  let in_arg f a b c =
    f
      (let (__windtrap_mut_7_l, __windtrap_mut_7_r) =
         (((a + b), c) : Windtrap_mut_________fixture_chain___ml.ints) in
       if Windtrap_mut_________fixture_chain___ml.___windtrap_armed___ 7
       then __windtrap_mut_7_l - __windtrap_mut_7_r
       else __windtrap_mut_7_l + __windtrap_mut_7_r)
  let conn_arg f a b c =
    f
      (a &&
         (let __windtrap_mut_8_p : Stdlib.Bool.t = b in
          (if
             Stdlib.(<>) __windtrap_mut_8_p
               (Windtrap_mut_________fixture_chain___ml.___windtrap_armed___ 8)
           then c
           else __windtrap_mut_8_p : Stdlib.Bool.t)))
  let siblings a b c d =
    let (__windtrap_mut_9_l, __windtrap_mut_9_r) =
      (((a + b),
         (let (__windtrap_mut_10_l, __windtrap_mut_10_r) =
            ((c, d) : Windtrap_mut_________fixture_chain___ml.ints) in
          if Windtrap_mut_________fixture_chain___ml.___windtrap_armed___ 10
          then __windtrap_mut_10_l - __windtrap_mut_10_r
          else __windtrap_mut_10_l + __windtrap_mut_10_r)) : Windtrap_mut_________fixture_chain___ml.ints) in
    if Windtrap_mut_________fixture_chain___ml.___windtrap_armed___ 9
    then __windtrap_mut_9_l - __windtrap_mut_9_r
    else __windtrap_mut_9_l + __windtrap_mut_9_r
  let mixed a b c =
    let (__windtrap_mut_11_l, __windtrap_mut_11_r) =
      (((let (__windtrap_mut_12_l, __windtrap_mut_12_r) =
           ((a, b) : Windtrap_mut_________fixture_chain___ml.ints) in
         if Windtrap_mut_________fixture_chain___ml.___windtrap_armed___ 12
         then __windtrap_mut_12_l - __windtrap_mut_12_r
         else __windtrap_mut_12_l + __windtrap_mut_12_r), c) : Windtrap_mut_________fixture_chain___ml.ints) in
    if Windtrap_mut_________fixture_chain___ml.___windtrap_armed___ 11
    then __windtrap_mut_11_l + __windtrap_mut_11_r
    else __windtrap_mut_11_l - __windtrap_mut_11_r
  let chained a b c =
    if
      let (__windtrap_mut_15_l, __windtrap_mut_15_r) =
        (((a < b), c) : _ Windtrap_mut_________fixture_chain___ml.operands) in
      (if Windtrap_mut_________fixture_chain___ml.___windtrap_armed___ 15
       then Stdlib.not (__windtrap_mut_15_r < __windtrap_mut_15_l)
       else __windtrap_mut_15_l < __windtrap_mut_15_r)
    then
      (if Windtrap_mut_________fixture_chain___ml.___windtrap_armed___ 14
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_chain___ml.___windtrap_armed___ 13
      then 1
      else 0

  $ mut --impl ./fixture_chain_off.ml | ../elide.exe
  mutation sites of "./fixture_chain_off.ml" in Windtrap_mut_________fixture_chain_off___ml, with type ints:
    0: 4:19-4:50 "sub" "((a + (b - d))[@mutate off]) + c" -> "((a + (b - d))[@mutate off]) - c"
    1: 9:17-9:50 "tail" "a :: (((b - 1) :: t)[@mutate off])" -> "(b - 1) :: t"
  let link a b c d =
    let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
      ((((a + (b - d))[@mutate off]), c) : Windtrap_mut_________fixture_chain_off___ml.ints) in
    if Windtrap_mut_________fixture_chain_off___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_l - __windtrap_mut_0_r
    else __windtrap_mut_0_l + __windtrap_mut_0_r
  let cons a b t =
    if
      Stdlib.not
        (Windtrap_mut_________fixture_chain_off___ml.___windtrap_armed___ 1)
    then a :: (((b - 1) :: t)[@mutate off])
    else (((b - 1) :: t)[@mutate off])

  $ mut --impl ./fixture_cmp.ml | ../elide.exe
  mutation sites of "./fixture_cmp.ml" in Windtrap_mut_________fixture_cmp___ml, with type 'a operands:
    0: 7:37-7:38 "int" "0" -> "1"
    1: 7:30-7:31 "int" "1" -> "0"
    2: 7:19-7:24 "le" "a < b" -> "a <= b"
    3: 8:40-8:41 "int" "0" -> "1"
    4: 8:33-8:34 "int" "1" -> "0"
    5: 8:21-8:27 "lt" "a <= b" -> "a < b"
    6: 11:8-11:13 "ge" "a > b" -> "a >= b"
    7: 15:49-15:50 "int" "1" -> "0"
    8: 15:39-15:45 "gt" "a >= b" -> "a > b"
    9: 15:58-15:59 "int" "0" -> "1"
    10: 16:36-16:37 "int" "0" -> "1"
    11: 16:29-16:30 "int" "1" -> "0"
    12: 16:18-16:23 "neq" "a = b" -> "a <> b"
    13: 17:40-17:41 "int" "0" -> "1"
    14: 17:33-17:34 "int" "1" -> "0"
    15: 17:21-17:27 "eq" "a <> b" -> "a = b"
    16: 20:21-20:39 "or" "(x >= lo) && (x <= hi)" -> "(x >= lo) || (x <= hi)"
    17: 20:21-20:28 "gt" "x >= lo" -> "x > lo"
    18: 20:32-20:39 "lt" "x <= hi" -> "x < hi"
  let below a b =
    if
      let (__windtrap_mut_2_l, __windtrap_mut_2_r) =
        ((a, b) : _ Windtrap_mut_________fixture_cmp___ml.operands) in
      (if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 2
       then Stdlib.not (__windtrap_mut_2_r < __windtrap_mut_2_l)
       else __windtrap_mut_2_l < __windtrap_mut_2_r)
    then
      (if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 1
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 0
      then 1
      else 0
  let at_most a b =
    if
      let (__windtrap_mut_5_l, __windtrap_mut_5_r) =
        ((a, b) : _ Windtrap_mut_________fixture_cmp___ml.operands) in
      (if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 5
       then Stdlib.not (__windtrap_mut_5_r <= __windtrap_mut_5_l)
       else __windtrap_mut_5_l <= __windtrap_mut_5_r)
    then
      (if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 4
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 3
      then 1
      else 0
  let above a b =
    while
      let (__windtrap_mut_6_l, __windtrap_mut_6_r) =
        ((a, b) : _ Windtrap_mut_________fixture_cmp___ml.operands) in
      if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 6
      then Stdlib.not (__windtrap_mut_6_r > __windtrap_mut_6_l)
      else __windtrap_mut_6_l > __windtrap_mut_6_r do () done
  let at_least a b =
    match a with
    | _ when
        let (__windtrap_mut_8_l, __windtrap_mut_8_r) =
          ((a, b) : _ Windtrap_mut_________fixture_cmp___ml.operands) in
        if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 8
        then Stdlib.not (__windtrap_mut_8_r >= __windtrap_mut_8_l)
        else __windtrap_mut_8_l >= __windtrap_mut_8_r ->
        if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 7
        then 0
        else 1
    | _ ->
        if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 9
        then 1
        else 0
  let same a b =
    if
      let __windtrap_mut_12_p : Stdlib.Bool.t = a = b in
      (if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 12
       then Stdlib.not __windtrap_mut_12_p
       else __windtrap_mut_12_p)
    then
      (if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 11
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 10
      then 1
      else 0
  let differs a b =
    if
      let __windtrap_mut_15_p : Stdlib.Bool.t = a <> b in
      (if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 15
       then Stdlib.not __windtrap_mut_15_p
       else __windtrap_mut_15_p)
    then
      (if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 14
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 13
      then 1
      else 0
  let window lo hi x =
    let __windtrap_mut_16_p : Stdlib.Bool.t =
      let (__windtrap_mut_17_l, __windtrap_mut_17_r) =
        ((x, lo) : _ Windtrap_mut_________fixture_cmp___ml.operands) in
      if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 17
      then Stdlib.not (__windtrap_mut_17_r >= __windtrap_mut_17_l)
      else __windtrap_mut_17_l >= __windtrap_mut_17_r in
    (if
       Stdlib.(<>) __windtrap_mut_16_p
         (Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 16)
     then
       let (__windtrap_mut_18_l, __windtrap_mut_18_r) =
         ((x, hi) : _ Windtrap_mut_________fixture_cmp___ml.operands) in
       (if Windtrap_mut_________fixture_cmp___ml.___windtrap_armed___ 18
        then Stdlib.not (__windtrap_mut_18_r <= __windtrap_mut_18_l)
        else __windtrap_mut_18_l <= __windtrap_mut_18_r)
     else __windtrap_mut_16_p : Stdlib.Bool.t)
  let ok a b = a < b
  let count a b = List.length (List.filter (fun x -> x < a) b)

  $ mut --impl ./fixture_con.ml | ../elide.exe
  mutation sites of "./fixture_con.ml" in Windtrap_mut_________fixture_con___ml:
    0: 8:15-8:21 "or" "a && b" -> "a || b"
    1: 9:17-9:23 "and" "a || b" -> "a && b"
    2: 10:45-10:46 "int" "0" -> "1"
    3: 10:38-10:39 "int" "1" -> "0"
    4: 10:22-10:32 "or" "ready && x" -> "ready || x"
    5: 11:34-11:39 "bool" "false" -> "true"
    6: 11:55-11:75 "and" "(p x) || (search p rest)" -> "(p x) && (search p rest)"
  let both a b =
    let __windtrap_mut_0_p : Stdlib.Bool.t = a in
    (if
       Stdlib.(<>) __windtrap_mut_0_p
         (Windtrap_mut_________fixture_con___ml.___windtrap_armed___ 0)
     then b
     else __windtrap_mut_0_p : Stdlib.Bool.t)
  let either a b =
    let __windtrap_mut_1_p : Stdlib.Bool.t = a in
    (if
       Stdlib.(=) __windtrap_mut_1_p
         (Windtrap_mut_________fixture_con___ml.___windtrap_armed___ 1)
     then b
     else __windtrap_mut_1_p : Stdlib.Bool.t)
  let gate ready x =
    if
      let __windtrap_mut_4_p : Stdlib.Bool.t = ready in
      ((if
          Stdlib.(<>) __windtrap_mut_4_p
            (Windtrap_mut_________fixture_con___ml.___windtrap_armed___ 4)
        then x
        else __windtrap_mut_4_p) : Stdlib.Bool.t)
    then
      (if Windtrap_mut_________fixture_con___ml.___windtrap_armed___ 3
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_con___ml.___windtrap_armed___ 2
      then 1
      else 0
  let rec search p =
    function
    | [] ->
        if Windtrap_mut_________fixture_con___ml.___windtrap_armed___ 5
        then true
        else false
    | x::rest ->
        let __windtrap_mut_6_p : Stdlib.Bool.t = p x in
        (if
           Stdlib.(=) __windtrap_mut_6_p
             (Windtrap_mut_________fixture_con___ml.___windtrap_armed___ 6)
         then search p rest
         else __windtrap_mut_6_p : Stdlib.Bool.t)

  $ mut --impl ./fixture_contexts.ml | ../elide.exe
  mutation sites of "./fixture_contexts.ml" in Windtrap_mut_________fixture_contexts___ml, with type 'a operands, type ints:
    0: 5:19-5:29 "and" "(a < b) || c" -> "(a < b) && c"
    1: 5:19-5:24 "le" "a < b" -> "a <= b"
    2: 15:7-15:8 "int" "0" -> "1"
    3: 14:7-14:8 "int" "1" -> "0"
    4: 12:4-13:9 "not" "let x = a in x < b" -> "not (let x = a in x < b)"
    5: 17:59-17:60 "int" "0" -> "1"
    6: 17:52-17:53 "int" "1" -> "0"
    7: 17:32-17:46 "not" "(a < b : bool)" -> "not (a < b : bool)"
    8: 18:49-18:50 "int" "0" -> "1"
    9: 18:42-18:43 "int" "1" -> "0"
    10: 18:25-18:36 "not" "not (a < b)" -> "not (not (a < b))"
    11: 23:55-23:56 "int" "0" -> "1"
    12: 23:48-23:49 "int" "1" -> "0"
    13: 23:34-23:42 "and" "c || d" -> "c && d"
    14: 23:25-23:30 "le" "a < b" -> "a <= b"
    15: 29:45-29:46 "int" "0" -> "1"
    16: 29:38-29:39 "int" "1" -> "0"
    17: 29:27-29:32 "not" "a & b" -> "not (a & b)"
    18: 34:61-34:62 "int" "0" -> "1"
    19: 34:54-34:55 "int" "1" -> "0"
    20: 34:33-34:48 "not" "Float.(<) a b" -> "not (Float.(<) a b)"
    21: 40:16-40:21 "sub" "a + b" -> "a - b"
  let either a b c =
    let __windtrap_mut_0_p : Stdlib.Bool.t =
      let (__windtrap_mut_1_l, __windtrap_mut_1_r) =
        ((a, b) : _ Windtrap_mut_________fixture_contexts___ml.operands) in
      if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 1
      then Stdlib.not (__windtrap_mut_1_r < __windtrap_mut_1_l)
      else __windtrap_mut_1_l < __windtrap_mut_1_r in
    (if
       Stdlib.(=) __windtrap_mut_0_p
         (Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 0)
     then c
     else __windtrap_mut_0_p : Stdlib.Bool.t)
  let through_let a b =
    if
      let __windtrap_mut_4_p : Stdlib.Bool.t = let x = a in x < b in
      (if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 4
       then Stdlib.not __windtrap_mut_4_p
       else __windtrap_mut_4_p)
    then
      (if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 3
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 2
      then 1
      else 0
  let through_constraint a b =
    if
      let __windtrap_mut_7_p : Stdlib.Bool.t = (a < b : bool) in
      (if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 7
       then Stdlib.not __windtrap_mut_7_p
       else __windtrap_mut_7_p)
    then
      (if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 6
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 5
      then 1
      else 0
  let through_not a b =
    if
      let __windtrap_mut_10_p : Stdlib.Bool.t = not (a < b) in
      (if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 10
       then Stdlib.not __windtrap_mut_10_p
       else __windtrap_mut_10_p)
    then
      (if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 9
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 8
      then 1
      else 0
  let skipped a b c d =
    if
      (let (__windtrap_mut_14_l, __windtrap_mut_14_r) =
         ((a, b) : _ Windtrap_mut_________fixture_contexts___ml.operands) in
       if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 14
       then Stdlib.not (__windtrap_mut_14_r < __windtrap_mut_14_l)
       else __windtrap_mut_14_l < __windtrap_mut_14_r) &&
        (let __windtrap_mut_13_p : Stdlib.Bool.t = c in
         ((if
             Stdlib.(=) __windtrap_mut_13_p
               (Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___
                  13)
           then d
           else __windtrap_mut_13_p) : Stdlib.Bool.t))
    then
      (if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 12
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 11
      then 1
      else 0
  let old_and a b = a & b
  let old_or a b = a or b
  let old_condition a b =
    if
      let __windtrap_mut_17_p : Stdlib.Bool.t = a & b in
      (if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 17
       then Stdlib.not __windtrap_mut_17_p
       else __windtrap_mut_17_p)
    then
      (if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 16
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 15
      then 1
      else 0
  let qualified a b = Stdlib.(+) a b
  let qualified_condition a b =
    if
      let __windtrap_mut_20_p : Stdlib.Bool.t = Float.(<) a b in
      (if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 20
       then Stdlib.not __windtrap_mut_20_p
       else __windtrap_mut_20_p)
    then
      (if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 19
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 18
      then 1
      else 0
  let partial = (+) 1
  let labelled a b = (+) ~a b
  let total a b =
    let (__windtrap_mut_21_l, __windtrap_mut_21_r) =
      ((a, b) : Windtrap_mut_________fixture_contexts___ml.ints) in
    if Windtrap_mut_________fixture_contexts___ml.___windtrap_armed___ 21
    then __windtrap_mut_21_l - __windtrap_mut_21_r
    else __windtrap_mut_21_l + __windtrap_mut_21_r

Some mutants are equivalent to the original in the syntax alone, or
change a log message or a failure message alone. Such a site is arid: the
rewriter records nothing for it and gives it no guard. The sites inside
it keep their mutants:

  $ mut --impl ./fixture_equivalent_ari.ml | ../elide.exe
  mutation sites of "./fixture_equivalent_ari.ml" in Windtrap_mut_________fixture_equivalent_ari___ml, with type ints, type floats:
    0: 10:13-10:18 "sub" "0 + x" -> "0 - x"
    1: 11:14-11:21 "fsub" "x +. 0." -> "x -. 0."
    2: 12:16-12:21 "sub" "a + b" -> "a - b"
    3: 13:17-13:23 "sub" "x + 0l" -> "x - 0l"
  let plus x = x + 0
  let minus x = x - 0
  let hex x = x + 0x0
  let left x =
    let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
      ((0, x) : Windtrap_mut_________fixture_equivalent_ari___ml.ints) in
    if Windtrap_mut_________fixture_equivalent_ari___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_l - __windtrap_mut_0_r
    else __windtrap_mut_0_l + __windtrap_mut_0_r
  let fplus x =
    let (__windtrap_mut_1_l, __windtrap_mut_1_r) =
      ((x, 0.) : Windtrap_mut_________fixture_equivalent_ari___ml.floats) in
    if Windtrap_mut_________fixture_equivalent_ari___ml.___windtrap_armed___ 1
    then __windtrap_mut_1_l -. __windtrap_mut_1_r
    else __windtrap_mut_1_l +. __windtrap_mut_1_r
  let chain a b =
    (let (__windtrap_mut_2_l, __windtrap_mut_2_r) =
       ((a, b) : Windtrap_mut_________fixture_equivalent_ari___ml.ints) in
     if Windtrap_mut_________fixture_equivalent_ari___ml.___windtrap_armed___ 2
     then __windtrap_mut_2_l - __windtrap_mut_2_r
     else __windtrap_mut_2_l + __windtrap_mut_2_r) + 0
  let suffixed x =
    let (__windtrap_mut_3_l, __windtrap_mut_3_r) =
      ((x, 0l) : Windtrap_mut_________fixture_equivalent_ari___ml.ints) in
    if Windtrap_mut_________fixture_equivalent_ari___ml.___windtrap_armed___ 3
    then __windtrap_mut_3_l - __windtrap_mut_3_r
    else __windtrap_mut_3_l + __windtrap_mut_3_r

  $ mut --impl ./fixture_equivalent_con.ml | ../elide.exe
  mutation sites of "./fixture_equivalent_con.ml" in Windtrap_mut_________fixture_equivalent_con___ml:
    0: 10:16-10:26 "or" "(f x) && (f x)" -> "(f x) || (f x)"
    1: 11:16-11:22 "or" "a && b" -> "a || b"
  type r = {
    mutable ok: bool }
  let both a = a && a
  let either a = a || a
  let field r = r.ok && r.ok
  let calls f x =
    let __windtrap_mut_0_p : Stdlib.Bool.t = f x in
    (if
       Stdlib.(<>) __windtrap_mut_0_p
         (Windtrap_mut_________fixture_equivalent_con___ml.___windtrap_armed___
            0)
     then f x
     else __windtrap_mut_0_p : Stdlib.Bool.t)
  let other a b =
    let __windtrap_mut_1_p : Stdlib.Bool.t = a in
    (if
       Stdlib.(<>) __windtrap_mut_1_p
         (Windtrap_mut_________fixture_equivalent_con___ml.___windtrap_armed___
            1)
     then b
     else __windtrap_mut_1_p : Stdlib.Bool.t)

  $ mut --impl ./fixture_equivalent_neg.ml | ../elide.exe
  mutation sites of "./fixture_equivalent_neg.ml" in Windtrap_mut_________fixture_equivalent_neg___ml, with type ints:
    0: 7:36-7:41 "sub" "x + 1" -> "x - 1"
    1: 7:25-7:30 "sub" "x + 1" -> "x - 1"
    2: 9:41-9:42 "int" "0" -> "1"
    3: 9:34-9:35 "int" "0" -> "1"
    4: 9:21-9:28 "sub" "x + 1" -> "x - 1"
    5: 10:20-10:26 "or" "a && b" -> "a || b"
    6: 11:31-11:32 "int" "2" -> "3"
    7: 11:24-11:25 "int" "1" -> "0"
    8: 11:17-11:18 "not" "c" -> "not c"
    9: 12:16-12:17 "not" "c" -> "not c"
    10: 13:18-13:19 "not" "c" -> "not c"
    11: 15:5-15:6 "not" "c" -> "not c"
  let flag c x =
    if c
    then
      let (__windtrap_mut_1_l, __windtrap_mut_1_r) =
        ((x, 1) : Windtrap_mut_________fixture_equivalent_neg___ml.ints) in
      (if
         Windtrap_mut_________fixture_equivalent_neg___ml.___windtrap_armed___
           1
       then __windtrap_mut_1_l - __windtrap_mut_1_r
       else __windtrap_mut_1_l + __windtrap_mut_1_r)
    else
      (let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
         ((x, 1) : Windtrap_mut_________fixture_equivalent_neg___ml.ints) in
       if
         Windtrap_mut_________fixture_equivalent_neg___ml.___windtrap_armed___
           0
       then __windtrap_mut_0_l - __windtrap_mut_0_r
       else __windtrap_mut_0_l + __windtrap_mut_0_r)
  let order a b x = if a < b then x else x
  let inner f x =
    if
      f
        (let (__windtrap_mut_4_l, __windtrap_mut_4_r) =
           ((x, 1) : Windtrap_mut_________fixture_equivalent_neg___ml.ints) in
         if
           Windtrap_mut_________fixture_equivalent_neg___ml.___windtrap_armed___
             4
         then __windtrap_mut_4_l - __windtrap_mut_4_r
         else __windtrap_mut_4_l + __windtrap_mut_4_r)
    then
      (if
         Windtrap_mut_________fixture_equivalent_neg___ml.___windtrap_armed___
           3
       then 1
       else 0)
    else
      if
        Windtrap_mut_________fixture_equivalent_neg___ml.___windtrap_armed___ 2
      then 1
      else 0
  let both a b x =
    if
      let __windtrap_mut_5_p : Stdlib.Bool.t = a in
      ((if
          Stdlib.(<>) __windtrap_mut_5_p
            (Windtrap_mut_________fixture_equivalent_neg___ml.___windtrap_armed___
               5)
        then b
        else __windtrap_mut_5_p) : Stdlib.Bool.t)
    then x
    else x
  let other c =
    if
      let __windtrap_mut_8_p : Stdlib.Bool.t = c in
      (if
         Windtrap_mut_________fixture_equivalent_neg___ml.___windtrap_armed___
           8
       then Stdlib.not __windtrap_mut_8_p
       else __windtrap_mut_8_p)
    then
      (if
         Windtrap_mut_________fixture_equivalent_neg___ml.___windtrap_armed___
           7
       then 0
       else 1)
    else
      if
        Windtrap_mut_________fixture_equivalent_neg___ml.___windtrap_armed___ 6
      then 3
      else 2
  let line c =
    if
      let __windtrap_mut_9_p : Stdlib.Bool.t = c in
      (if
         Windtrap_mut_________fixture_equivalent_neg___ml.___windtrap_armed___
           9
       then Stdlib.not __windtrap_mut_9_p
       else __windtrap_mut_9_p)
    then __LINE__
    else __LINE__
  let blanks c =
    if
      let __windtrap_mut_10_p : Stdlib.Bool.t = c in
      (if
         Windtrap_mut_________fixture_equivalent_neg___ml.___windtrap_armed___
           10
       then Stdlib.not __windtrap_mut_10_p
       else __windtrap_mut_10_p)
    then "a  b"
    else "a b"
  let partial c x =
    if
      let __windtrap_mut_11_p : Stdlib.Bool.t = c in
      (if
         Windtrap_mut_________fixture_equivalent_neg___ml.___windtrap_armed___
           11
       then Stdlib.not __windtrap_mut_11_p
       else __windtrap_mut_11_p)
    then match x with | Some y -> y
    else (match x with | Some y -> y)
  let equal a b x = if a = b then x else x

Each rule reads these forms, and a form that it does not read keeps its
mutant:

  $ sites() { mut "$@" | ../elide.exe | grep -E '^ +[0-9]+: '; }
  $ sites --impl ./fixture_equivalent_forms.ml
    0: 9:15-9:16 "not" "c" -> "not c"
    1: 10:20-10:21 "not" "c" -> "not c"
    2: 11:21-11:22 "not" "c" -> "not c"
    3: 12:20-12:21 "not" "c" -> "not c"
    4: 15:68-15:73 "ge" "y > 0" -> "y >= 0"
    5: 15:72-15:73 "int" "0" -> "1"
    6: 15:32-15:37 "ge" "y > 0" -> "y >= 0"
    7: 15:36-15:37 "int" "0" -> "1"
    8: 15:5-15:6 "not" "c" -> "not c"
    9: 18:60-18:65 "ge" "y > 0" -> "y >= 0"
    10: 18:64-18:65 "int" "0" -> "1"
    11: 18:28-18:33 "ge" "y > 0" -> "y >= 0"
    12: 18:32-18:33 "int" "0" -> "1"
    13: 18:5-18:6 "not" "c" -> "not c"
    14: 20:63-20:68 "sub" "a + b" -> "a - b"
    15: 20:38-20:43 "sub" "a + b" -> "a - b"
    16: 23:50-23:51 "int" "0" -> "1"
    17: 23:33-23:34 "int" "0" -> "1"

Code that gives its location keeps the mutants of its two copies:

  $ sites --impl ./fixture_equivalent_located.ml
    0: 9:20-9:25 "ge" "x > 0" -> "x >= 0"
    1: 9:24-9:25 "int" "0" -> "1"
    2: 10:15-10:16 "not" "c" -> "not c"
    3: 11:21-11:22 "not" "c" -> "not c"
    4: 12:15-12:16 "not" "c" -> "not c"
    5: 13:16-13:17 "not" "c" -> "not c"
    6: 14:21-14:22 "not" "c" -> "not c"
    7: 17:21-17:22 "not" "c" -> "not c"
    8: 18:23-18:24 "not" "c" -> "not c"
    9: 19:18-19:19 "not" "c" -> "not c"
    10: 20:74-20:75 "int" "1" -> "0"
    11: 20:46-20:47 "int" "1" -> "0"
    12: 20:19-20:20 "not" "c" -> "not c"
    13: 21:70-21:71 "int" "1" -> "0"
    14: 21:48-21:49 "int" "1" -> "0"
    15: 21:26-21:27 "not" "c" -> "not c"

  $ sites --impl ./fixture_equivalent_mul.ml
    0: 16:20-16:21 "int" "0" -> "1"
    1: 17:18-17:19 "int" "0" -> "1"
    2: 18:18-18:19 "int" "0" -> "1"
    3: 19:19-19:20 "int" "0" -> "1"
    4: 24:17-24:22 "div" "1 * x" -> "1 / x"
    5: 25:16-25:23 "mod" "x mod 1" -> "x * 1"
    6: 26:18-26:26 "mod" "x mod (-1)" -> "x * (-1)"
    7: 27:16-27:21 "div" "x * 0" -> "x / 0"
    8: 28:18-28:23 "div" "0 * x" -> "0 / x"
    9: 29:16-29:23 "land" "x lor 0" -> "x land 0"
    10: 29:22-29:23 "int" "0" -> "1"
    11: 30:16-30:25 "lor" "x land (-1)" -> "x lor (-1)"
    12: 30:23-30:25 "int" "(-1)" -> "0"
    13: 31:17-31:25 "xor" "x lxor 0" -> "x land 0"
    14: 31:24-31:25 "int" "0" -> "1"
    15: 32:17-32:25 "xor" "a lxor a" -> "a land a"
    16: 33:18-33:25 "fdiv" "1. *. x" -> "1. /. x"
    17: 34:14-34:21 "fdiv" "x *. 0." -> "x /. 0."
    18: 35:20-35:33 "div" "x * (1 : int)" -> "x / (1 : int)"
    19: 35:25-35:26 "int" "1" -> "0"
    20: 38:16-38:21 "div" "a * b" -> "a / b"

  $ mut --impl ./fixture_equivalent_log.ml | ../elide.exe
  mutation sites of "./fixture_equivalent_log.ml" in Windtrap_mut_________fixture_equivalent_log___ml, with type ints:
    0: 12:33-12:40 "sub" "x + 1" -> "x - 1"
    1: 15:2-15:37 "del" "Log.debug (fun m -> m \"%d\" (x + 1))" -> "()"
    2: 15:29-15:36 "sub" "x + 1" -> "x - 1"
    3: 25:2-28:16 "del" "Logs.debug (fun m -> y := ((!y) + 1); (let () = incr y in m \"%d\" (!y)))" -> "()"
    4: 26:6-26:17 "del" "y := ((!y) + 1)" -> "()"
    5: 26:11-26:17 "sub" "(!y) + 1" -> "(!y) - 1"
    6: 27:15-27:21 "decr" "incr y" -> "decr y"
    7: 29:2-29:8 "sub" "(!y) + x" -> "(!y) - x"
  let debug x =
    Logs.debug
      (fun m -> m "%d %a" (x + 1) (let open Fmt in option int) (Some x))
  let info x = Logs.info @@ (fun m -> m "%d" (x - 1))
  let print x =
    Printf.printf "%d"
      (let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
         ((x, 1) : Windtrap_mut_________fixture_equivalent_log___ml.ints) in
       if
         Windtrap_mut_________fixture_equivalent_log___ml.___windtrap_armed___
           0
       then __windtrap_mut_0_l - __windtrap_mut_0_r
       else __windtrap_mut_0_l + __windtrap_mut_0_r)
  let local x =
    (if Windtrap_mut_________fixture_equivalent_log___ml.___windtrap_armed___ 1
     then ((())[@ocaml.warning "-41-42"])
     else
       (Log.debug
          (fun m ->
             m "%d"
               (let (__windtrap_mut_2_l, __windtrap_mut_2_r) =
                  ((x, 1) : Windtrap_mut_________fixture_equivalent_log___ml.ints) in
                if
                  Windtrap_mut_________fixture_equivalent_log___ml.___windtrap_armed___
                    2
                then __windtrap_mut_2_l - __windtrap_mut_2_r
                else __windtrap_mut_2_l + __windtrap_mut_2_r));
        ((())
        [@ocaml.warning "-41-42"])) : Stdlib.Unit.t);
    x
  let app x = Logs.app (fun m -> m "%d" (x + 1))
  let err x = Logs.err (fun m -> m "%d" (x + 1))
  let warn x = Logs.warn (fun m -> m "%d" (x + 1))
  let msg x = Logs.msg Logs.Info (fun m -> m "%d" (x + 1))
  let listed x = Logs.debug (fun m -> m "%a" (let open Fmt in list int) [x; 2])
  let counted y x =
    (if Windtrap_mut_________fixture_equivalent_log___ml.___windtrap_armed___ 3
     then ((())[@ocaml.warning "-41-42"])
     else
       (Logs.debug
          (fun m ->
             (if
                Windtrap_mut_________fixture_equivalent_log___ml.___windtrap_armed___
                  4
              then ((())[@ocaml.warning "-41-42"])
              else
                (y :=
                   ((let (__windtrap_mut_5_l, __windtrap_mut_5_r) =
                       (((!y), 1) : Windtrap_mut_________fixture_equivalent_log___ml.ints) in
                     if
                       Windtrap_mut_________fixture_equivalent_log___ml.___windtrap_armed___
                         5
                     then __windtrap_mut_5_l - __windtrap_mut_5_r
                     else __windtrap_mut_5_l + __windtrap_mut_5_r));
                 ((())
                 [@ocaml.warning "-41-42"])) : Stdlib.Unit.t);
             (let () =
                if
                  Windtrap_mut_________fixture_equivalent_log___ml.___windtrap_armed___
                    6
                then decr y
                else incr y in
              m "%d" (!y)));
        ((())
        [@ocaml.warning "-41-42"])) : Stdlib.Unit.t);
    (let (__windtrap_mut_7_l, __windtrap_mut_7_r) =
       (((!y), x) : Windtrap_mut_________fixture_equivalent_log___ml.ints) in
     if Windtrap_mut_________fixture_equivalent_log___ml.___windtrap_armed___ 7
     then __windtrap_mut_7_l - __windtrap_mut_7_r
     else __windtrap_mut_7_l + __windtrap_mut_7_r)
  let guarded c n = Logs.debug (fun m -> if c then m "%d" (n + 1))
  let looped n = Logs.debug (fun m -> for i = 1 to n do m "%d" (i + 1) done)

  $ sites --impl ./fixture_equivalent_log_bound.ml
    0: 8:37-8:44 "sub" "x + 1" -> "x - 1"

  $ sites --impl ./fixture_equivalent_log_letmodule.ml
    0: 7:25-7:32 "sub" "x + 1" -> "x - 1"

  $ sites --impl ./fixture_equivalent_log_signature.ml
    0: 10:37-10:44 "sub" "x + 1" -> "x - 1"

  $ sites --impl ./fixture_equivalent_log_unpack.ml
    0: 4:55-4:62 "sub" "x + 1" -> "x - 1"

  $ sites --impl ./fixture_equivalent_log_functor.ml
    0: 5:39-5:46 "sub" "x + 1" -> "x - 1"

  $ mut --impl ./fixture_equivalent_message.ml | ../elide.exe
  mutation sites of "./fixture_equivalent_message.ml" in Windtrap_mut_________fixture_equivalent_message___ml, with type ints:
    0: 8:54-8:61 "sub" "n + 1" -> "n - 1"
    1: 12:55-12:56 "int" "6" -> "7"
    2: 17:64-17:72 "none" "Some n" -> "None"
    3: 18:25-18:31 "del" "r := 5" -> "()"
    4: 18:30-18:31 "int" "5" -> "6"
    5: 19:41-19:42 "int" "7" -> "8"
  let fail n =
    failwith
      (Printf.sprintf "item %d of %d"
         (let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
            ((n, 1) : Windtrap_mut_________fixture_equivalent_message___ml.ints) in
          if
            Windtrap_mut_________fixture_equivalent_message___ml.___windtrap_armed___
              0
          then __windtrap_mut_0_l - __windtrap_mut_0_r
          else __windtrap_mut_0_l + __windtrap_mut_0_r) 10)
  let invalid () = Stdlib.invalid_arg (string_of_int 3)
  let formatted () = Printf.ksprintf failwith "code %d" 4
  let piped () = (string_of_int 5) |> failwith
  let raised () =
    raise
      (Invalid_argument
         (string_of_int
            (if
               Windtrap_mut_________fixture_equivalent_message___ml.___windtrap_armed___
                 1
             then 7
             else 6)))
  let kformatted () = Format.kasprintf failwith "code %d" 8
  let qualified () = Stdlib.failwith (string_of_int 9)
  let zero () = failwith (string_of_int 0)
  let flag () = failwith (string_of_bool true)
  let some n =
    failwith
      (Option.fold ~none:"" ~some:string_of_int
         (if
            Stdlib.not
              (Windtrap_mut_________fixture_equivalent_message___ml.___windtrap_armed___
                 2)
          then Some n
          else ((None)[@ocaml.warning "-18-41-42"])))
  let stated r =
    failwith
      ((if
          Windtrap_mut_________fixture_equivalent_message___ml.___windtrap_armed___
            3
        then ((())[@ocaml.warning "-41-42"])
        else
          (r :=
             (if
                Windtrap_mut_________fixture_equivalent_message___ml.___windtrap_armed___
                  4
              then 6
              else 5);
           ((())
           [@ocaml.warning "-41-42"])) : Stdlib.Unit.t);
       "boom")
  let bound r =
    invalid_arg
      (let () =
         r :=
           (if
              Windtrap_mut_________fixture_equivalent_message___ml.___windtrap_armed___
                5
            then 8
            else 7) in
       "boom")

  $ sites --impl ./fixture_equivalent_message_bound.ml
    0: 3:17-3:22 "sub" "n + 1" -> "n - 1"
    1: 4:23-4:24 "int" "7" -> "8"

  $ sites --impl ./fixture_equivalent_message_bound_invalid.ml
    0: 3:20-3:25 "sub" "n + 1" -> "n - 1"
    1: 4:26-4:27 "int" "7" -> "8"

A [@mutate off] on a site that a rule would make arid dismisses the site,
and keeps its reason:

  $ sites --impl ./fixture_equivalent_off.ml
    0: 5:13-5:20 "sub" "x + 0" -> "x - 0", dismissed "zero is kept"
    1: 6:13-6:21 "or" "a && a" -> "a || a", dismissed "one operand"
    2: 7:18-7:48 "not" "c" -> "not c", dismissed "one branch"
    3: 8:42-8:73 "sub" "x + 1" -> "x - 1", dismissed "a log"
    4: 9:38-9:67 "int" "3" -> "4", dismissed "a message"

  $ mut --impl ./fixture_empty.ml | ../elide.exe
  type t =
    | A 
    | B 
  let x = 1
  let s = "hello"
  let pair a b = (a, b)

  $ mut --impl ./fixture_exclude.ml | ../elide.exe
  [@@@mutate exclude_file]
  let sum a b = a + b
  let ordered a b = if a < b then 1 else 0

  $ mut --impl ./fixture_inline_tests.ml | ../elide.exe
  mutation sites of "./fixture_inline_tests.ml" in Windtrap_mut_________fixture_inline_tests___ml, with type 'a operands, type ints:
    0: 6:14-6:19 "sub" "a + b" -> "a - b"
    1: 7:39-7:40 "int" "0" -> "1"
    2: 7:32-7:33 "int" "1" -> "0"
    3: 7:21-7:26 "le" "a < b" -> "a <= b"
  let sum a b =
    let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
      ((a, b) : Windtrap_mut_________fixture_inline_tests___ml.ints) in
    if Windtrap_mut_________fixture_inline_tests___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_l - __windtrap_mut_0_r
    else __windtrap_mut_0_l + __windtrap_mut_0_r
  let ordered a b =
    if
      let (__windtrap_mut_3_l, __windtrap_mut_3_r) =
        ((a, b) : _ Windtrap_mut_________fixture_inline_tests___ml.operands) in
      (if Windtrap_mut_________fixture_inline_tests___ml.___windtrap_armed___ 3
       then Stdlib.not (__windtrap_mut_3_r < __windtrap_mut_3_l)
       else __windtrap_mut_3_l < __windtrap_mut_3_r)
    then
      (if Windtrap_mut_________fixture_inline_tests___ml.___windtrap_armed___ 2
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_inline_tests___ml.___windtrap_armed___ 1
      then 1
      else 0
  [%%test let "sums" = if (sum 1 2) = 3 then () else failwith "sum"]
  [%%test
    module Grouped =
      struct
        let twice x = x + x
        [%%test
          let "orders" =
            if (ordered 1 (twice 1)) > 0 then () else failwith "order"]
      end]
  [%%expect_test let "prints" = print_int ((sum 1 2) - 1); [%expect {| 2 |}]]

  $ ../pp.exe -apply ppx_windtrap,windtrap_mutate --impl ./fixture_inline_tests.ml | ../elide.exe
  mutation sites of "./fixture_inline_tests.ml" in Windtrap_mut_________fixture_inline_tests___ml, with type 'a operands, type ints:
    0: 6:14-6:19 "sub" "a + b" -> "a - b"
    1: 7:39-7:40 "int" "0" -> "1"
    2: 7:32-7:33 "int" "1" -> "0"
    3: 7:21-7:26 "le" "a < b" -> "a <= b"
  let sum a b =
    let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
      ((a, b) : Windtrap_mut_________fixture_inline_tests___ml.ints) in
    if Windtrap_mut_________fixture_inline_tests___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_l - __windtrap_mut_0_r
    else __windtrap_mut_0_l + __windtrap_mut_0_r
  let ordered a b =
    if
      let (__windtrap_mut_3_l, __windtrap_mut_3_r) =
        ((a, b) : _ Windtrap_mut_________fixture_inline_tests___ml.operands) in
      (if Windtrap_mut_________fixture_inline_tests___ml.___windtrap_armed___ 3
       then Stdlib.not (__windtrap_mut_3_r < __windtrap_mut_3_l)
       else __windtrap_mut_3_l < __windtrap_mut_3_r)
    then
      (if Windtrap_mut_________fixture_inline_tests___ml.___windtrap_armed___ 2
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_inline_tests___ml.___windtrap_armed___ 1
      then 1
      else 0
  let () =
    Ppx_windtrap_runtime.Ppx_runtime.add_test ~file:"./fixture_inline_tests.ml"
      ~pos:("./fixture_inline_tests.ml", 8, 0, 60) ~tags:[] "sums"
      (fun () ->
         match (if (sum 1 2) = 3 then () else failwith "sum" : unit) with
         | () -> ()
         | exception __windtrap_e -> Stdlib.raise_notrace __windtrap_e)
    [@@windtrap.test ]
  let () =
    Ppx_windtrap_runtime.Ppx_runtime.enter_group
      ~file:"./fixture_inline_tests.ml" ~tags:[] "Grouped"[@@windtrap.test ]
  module Grouped =
    struct
      let twice x = x + x
      let () =
        Ppx_windtrap_runtime.Ppx_runtime.add_test
          ~file:"./fixture_inline_tests.ml"
          ~pos:("./fixture_inline_tests.ml", 12, 2, 78) ~tags:[] "orders"
          (fun () ->
             match (if (ordered 1 (twice 1)) > 0 then () else failwith "order" : 
               unit)
             with
             | () -> ()
             | exception __windtrap_e -> Stdlib.raise_notrace __windtrap_e)
        [@@windtrap.test ]
    end[@@windtrap.test ]
  let () = Ppx_windtrap_runtime.Ppx_runtime.leave_group ()[@@windtrap.test ]
  let () =
    Ppx_windtrap_runtime.Ppx_runtime.add_test ~file:"./fixture_inline_tests.ml"
      ~pos:("./fixture_inline_tests.ml", 15, 0, 73) ~tags:[] "prints"
      (fun () ->
         Ppx_windtrap_runtime.Ppx_runtime.expect_test
           ~pos:("./fixture_inline_tests.ml", 15, 0, 73)
           ~body_end:("./fixture_inline_tests.ml", 17, 19, 19)
           ~nodes:[("./fixture_inline_tests.ml", 17, 2, 19)]
           (fun () ->
              (Expect_test_config.run : (unit -> unit) -> unit)
                (fun () ->
                   match (print_int ((sum 1 2) - 1);
                          Ppx_windtrap_runtime.Ppx_runtime.reach
                            ("./fixture_inline_tests.ml", 17, 2, 19);
                          Windtrap.expect
                            (Expect_test_config.sanitize (Windtrap.output ()))
                            (("./fixture_inline_tests.ml", 17, 2, 19), {| 2 |}) : 
                     unit)
                   with
                   | () -> ()
                   | exception __windtrap_e ->
                       Stdlib.raise_notrace __windtrap_e))
           (fun () -> Expect_test_config.sanitize (Windtrap.output ())))
    [@@windtrap.test ]

  $ mut --impl ./fixture_lazy.ml | ../elide.exe
  mutation sites of "./fixture_lazy.ml" in Windtrap_mut_________fixture_lazy___ml, with type ints:
    0: 10:22-10:29 "sub" "a + b" -> "a - b"
    1: 17:25-17:30 "sub" "a + b" -> "a - b"
  let thunk a b = lazy (fun () -> a + b)
  let forced a b =
    lazy
      (let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
         ((a, b) : Windtrap_mut_________fixture_lazy___ml.ints) in
       if Windtrap_mut_________fixture_lazy___ml.___windtrap_armed___ 0
       then __windtrap_mut_0_l - __windtrap_mut_0_r
       else __windtrap_mut_0_l + __windtrap_mut_0_r)
  let plain x = lazy x
  let annotated a b = lazy (fun () -> a + b : unit -> int)
  let computed a b =
    lazy
      (let (__windtrap_mut_1_l, __windtrap_mut_1_r) =
         ((a, b) : Windtrap_mut_________fixture_lazy___ml.ints) in
       if Windtrap_mut_________fixture_lazy___ml.___windtrap_armed___ 1
       then __windtrap_mut_1_l - __windtrap_mut_1_r
       else __windtrap_mut_1_l + __windtrap_mut_1_r : int)

  $ mut --impl ./fixture_lazy_condition.ml | ../elide.exe
  mutation sites of "./fixture_lazy_condition.ml" in Windtrap_mut_________fixture_lazy_condition___ml:
    0: 3:39-3:40 "int" "0" -> "1"
    1: 3:32-3:33 "int" "1" -> "0"
    2: 4:31-4:32 "int" "0" -> "1"
    3: 4:24-4:25 "int" "1" -> "0"
    4: 4:17-4:18 "not" "x" -> "not x"
  let deferred x =
    if lazy x
    then
      (if
         Windtrap_mut_________fixture_lazy_condition___ml.___windtrap_armed___
           1
       then 0
       else 1)
    else
      if
        Windtrap_mut_________fixture_lazy_condition___ml.___windtrap_armed___ 0
      then 1
      else 0
  let plain x =
    if
      let __windtrap_mut_4_p : Stdlib.Bool.t = x in
      (if
         Windtrap_mut_________fixture_lazy_condition___ml.___windtrap_armed___
           4
       then Stdlib.not __windtrap_mut_4_p
       else __windtrap_mut_4_p)
    then
      (if
         Windtrap_mut_________fixture_lazy_condition___ml.___windtrap_armed___
           3
       then 0
       else 1)
    else
      if
        Windtrap_mut_________fixture_lazy_condition___ml.___windtrap_armed___ 2
      then 1
      else 0

  $ mut --impl ./fixture_lost_alias.ml | ../elide.exe
  mutation sites of "./fixture_lost_alias.ml" in Windtrap_mut_________fixture_lost_alias___ml, with type 'a operands:
    0: 7:22-7:27 "le" "a < b" -> "a <= b"
  let times ((_ as ( * )) : float -> float -> float) a b = a * b
  let plus ((_ as (+)) : float -> float -> float) a b = a + b
  let pick a b x y =
    if
      let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
        ((a, b) : _ Windtrap_mut_________fixture_lost_alias___ml.operands) in
      (if Windtrap_mut_________fixture_lost_alias___ml.___windtrap_armed___ 0
       then Stdlib.not (__windtrap_mut_0_r < __windtrap_mut_0_l)
       else __windtrap_mut_0_l < __windtrap_mut_0_r)
    then x
    else y

  $ mut --impl ./fixture_lost_cmp.ml | ../elide.exe
  mutation sites of "./fixture_lost_cmp.ml" in Windtrap_mut_________fixture_lost_cmp___ml, with type ints:
    0: 8:32-8:33 "int" "0" -> "1"
    1: 10:43-10:48 "add" "a - b" -> "a + b"
    2: 10:32-10:37 "sub" "a + b" -> "a - b"
    3: 10:21-10:26 "not" "a < b" -> "not (a < b)"
    4: 11:37-11:38 "int" "0" -> "1"
    5: 11:30-11:31 "int" "1" -> "0"
    6: 11:18-11:24 "or" "a && b" -> "a || b"
  let (<=) a b =
    (compare a b) <=
      (if Windtrap_mut_________fixture_lost_cmp___ml.___windtrap_armed___ 0
       then 1
       else 0)
  let not b = b
  let ordered a b =
    if
      let __windtrap_mut_3_p : Stdlib.Bool.t = a < b in
      (if Windtrap_mut_________fixture_lost_cmp___ml.___windtrap_armed___ 3
       then Stdlib.not __windtrap_mut_3_p
       else __windtrap_mut_3_p)
    then
      let (__windtrap_mut_2_l, __windtrap_mut_2_r) =
        ((a, b) : Windtrap_mut_________fixture_lost_cmp___ml.ints) in
      (if Windtrap_mut_________fixture_lost_cmp___ml.___windtrap_armed___ 2
       then __windtrap_mut_2_l - __windtrap_mut_2_r
       else __windtrap_mut_2_l + __windtrap_mut_2_r)
    else
      (let (__windtrap_mut_1_l, __windtrap_mut_1_r) =
         ((a, b) : Windtrap_mut_________fixture_lost_cmp___ml.ints) in
       if Windtrap_mut_________fixture_lost_cmp___ml.___windtrap_armed___ 1
       then __windtrap_mut_1_l + __windtrap_mut_1_r
       else __windtrap_mut_1_l - __windtrap_mut_1_r)
  let both a b =
    if
      let __windtrap_mut_6_p : Stdlib.Bool.t = a in
      ((if
          Stdlib.(<>) __windtrap_mut_6_p
            (Windtrap_mut_________fixture_lost_cmp___ml.___windtrap_armed___ 6)
        then b
        else __windtrap_mut_6_p) : Stdlib.Bool.t)
    then
      (if Windtrap_mut_________fixture_lost_cmp___ml.___windtrap_armed___ 5
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_lost_cmp___ml.___windtrap_armed___ 4
      then 1
      else 0

  $ mut --impl ./fixture_lost_con.ml | ../elide.exe
  mutation sites of "./fixture_lost_con.ml" in Windtrap_mut_________fixture_lost_con___ml, with type 'a operands, type ints:
    0: 11:37-11:38 "int" "0" -> "1"
    1: 11:30-11:31 "int" "1" -> "0"
    2: 11:18-11:24 "not" "a && b" -> "not (a && b)"
    3: 12:39-12:40 "int" "0" -> "1"
    4: 12:32-12:33 "int" "1" -> "0"
    5: 12:20-12:26 "not" "a || b" -> "not (a || b)"
    6: 13:47-13:48 "int" "0" -> "1"
    7: 13:40-13:41 "int" "1" -> "0"
    8: 13:24-13:34 "not" "(a < b) && c" -> "not ((a < b) && c)"
    9: 14:43-14:48 "add" "a - b" -> "a + b"
    10: 14:32-14:37 "sub" "a + b" -> "a - b"
    11: 14:21-14:26 "le" "a < b" -> "a <= b"
  external (&&) : bool -> bool -> bool = "%sequand"
  let both a b =
    if
      let __windtrap_mut_2_p : Stdlib.Bool.t = a && b in
      (if Windtrap_mut_________fixture_lost_con___ml.___windtrap_armed___ 2
       then Stdlib.not __windtrap_mut_2_p
       else __windtrap_mut_2_p)
    then
      (if Windtrap_mut_________fixture_lost_con___ml.___windtrap_armed___ 1
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_lost_con___ml.___windtrap_armed___ 0
      then 1
      else 0
  let either a b =
    if
      let __windtrap_mut_5_p : Stdlib.Bool.t = a || b in
      (if Windtrap_mut_________fixture_lost_con___ml.___windtrap_armed___ 5
       then Stdlib.not __windtrap_mut_5_p
       else __windtrap_mut_5_p)
    then
      (if Windtrap_mut_________fixture_lost_con___ml.___windtrap_armed___ 4
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_lost_con___ml.___windtrap_armed___ 3
      then 1
      else 0
  let compared a b c =
    if
      let __windtrap_mut_8_p : Stdlib.Bool.t = (a < b) && c in
      (if Windtrap_mut_________fixture_lost_con___ml.___windtrap_armed___ 8
       then Stdlib.not __windtrap_mut_8_p
       else __windtrap_mut_8_p)
    then
      (if Windtrap_mut_________fixture_lost_con___ml.___windtrap_armed___ 7
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_lost_con___ml.___windtrap_armed___ 6
      then 1
      else 0
  let ordered a b =
    if
      let (__windtrap_mut_11_l, __windtrap_mut_11_r) =
        ((a, b) : _ Windtrap_mut_________fixture_lost_con___ml.operands) in
      (if Windtrap_mut_________fixture_lost_con___ml.___windtrap_armed___ 11
       then Stdlib.not (__windtrap_mut_11_r < __windtrap_mut_11_l)
       else __windtrap_mut_11_l < __windtrap_mut_11_r)
    then
      let (__windtrap_mut_10_l, __windtrap_mut_10_r) =
        ((a, b) : Windtrap_mut_________fixture_lost_con___ml.ints) in
      (if Windtrap_mut_________fixture_lost_con___ml.___windtrap_armed___ 10
       then __windtrap_mut_10_l - __windtrap_mut_10_r
       else __windtrap_mut_10_l + __windtrap_mut_10_r)
    else
      (let (__windtrap_mut_9_l, __windtrap_mut_9_r) =
         ((a, b) : Windtrap_mut_________fixture_lost_con___ml.ints) in
       if Windtrap_mut_________fixture_lost_con___ml.___windtrap_armed___ 9
       then __windtrap_mut_9_l + __windtrap_mut_9_r
       else __windtrap_mut_9_l - __windtrap_mut_9_r)

  $ sites --impl ./fixture_lost_mul.ml
    0: 9:19-9:20 "int" "2" -> "3"
    1: 10:14-10:19 "sub" "a + b" -> "a - b"
    2: 11:15-11:20 "add" "a - b" -> "a + b"
    3: 12:17-12:23 "fdiv" "a *. b" -> "a /. b"
    4: 13:15-13:23 "lor" "a land b" -> "a lor b"

  $ sites --impl ./fixture_lost_fmul_bit.ml
    0: 10:16-10:21 "div" "a * b" -> "a / b"
    1: 11:14-11:19 "sub" "a + b" -> "a - b"

  $ mut --impl ./fixture_lost_counter.ml | ../elide.exe
  mutation sites of "./fixture_lost_counter.ml" in Windtrap_mut_________fixture_lost_counter___ml, with type ints:
    0: 4:18-4:24 "add" "(!r) - 2" -> "(!r) + 2"
    1: 9:16-9:18 "pos" "- x" -> "x"
    2: 10:14-10:19 "sub" "a + b" -> "a - b"
  let decr r =
    r :=
      (let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
         (((!r), 2) : Windtrap_mut_________fixture_lost_counter___ml.ints) in
       if Windtrap_mut_________fixture_lost_counter___ml.___windtrap_armed___ 0
       then __windtrap_mut_0_l + __windtrap_mut_0_r
       else __windtrap_mut_0_l - __windtrap_mut_0_r)
  let up r = incr r
  let down r = decr r
  let atomic_up (a : int Atomic.t) = Atomic.incr a
  let atomic_down (a : int Atomic.t) = Atomic.decr a
  let negated x =
    let __windtrap_mut_1_p : Stdlib.Int.t = x in
    if Windtrap_mut_________fixture_lost_counter___ml.___windtrap_armed___ 1
    then __windtrap_mut_1_p
    else - __windtrap_mut_1_p
  let sum a b =
    let (__windtrap_mut_2_l, __windtrap_mut_2_r) =
      ((a, b) : Windtrap_mut_________fixture_lost_counter___ml.ints) in
    if Windtrap_mut_________fixture_lost_counter___ml.___windtrap_armed___ 2
    then __windtrap_mut_2_l - __windtrap_mut_2_r
    else __windtrap_mut_2_l + __windtrap_mut_2_r

  $ mut --impl ./fixture_counter_class.ml | ../elide.exe
  mutation sites of "./fixture_counter_class.ml" in Windtrap_mut_________fixture_counter_class___ml, with type ints:
    0: 8:43-8:50 "sub" "c.n + 1" -> "c.n - 1"
  type counter = {
    mutable n: int }
  let o =
    object
      val incr =
        fun (c : counter) ->
          c.n <-
            (let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
               (((c.n), 1) : Windtrap_mut_________fixture_counter_class___ml.ints) in
             if
               Windtrap_mut_________fixture_counter_class___ml.___windtrap_armed___
                 0
             then __windtrap_mut_0_l - __windtrap_mut_0_r
             else __windtrap_mut_0_l + __windtrap_mut_0_r)
      method bump c = incr c
    end
  let up r = incr r

  $ mut --impl ./fixture_lost_pos.ml | ../elide.exe
  mutation sites of "./fixture_lost_pos.ml" in Windtrap_mut_________fixture_lost_pos___ml, with type ints:
    0: 7:14-7:19 "sub" "a + b" -> "a - b"
  let (~-.) x = x
  let negate x = - x
  let fnegate x = -. x
  let sum a b =
    let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
      ((a, b) : Windtrap_mut_________fixture_lost_pos___ml.ints) in
    if Windtrap_mut_________fixture_lost_pos___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_l - __windtrap_mut_0_r
    else __windtrap_mut_0_l + __windtrap_mut_0_r

  $ mut --impl ./fixture_lost_ari_pos.ml | ../elide.exe
  mutation sites of "./fixture_lost_ari_pos.ml" in Windtrap_mut_________fixture_lost_ari_pos___ml:
    0: 6:15-6:17 "pos" "- x" -> "x"
    1: 7:16-7:19 "pos" "-. x" -> "x"
    2: 8:19-8:23 "pos" "- b" -> "b"
  let (-) a b = a + b
  let (-.) a b = a +. b
  let negate x =
    let __windtrap_mut_0_p : Stdlib.Int.t = x in
    if Windtrap_mut_________fixture_lost_ari_pos___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_p
    else - __windtrap_mut_0_p
  let fnegate x =
    let __windtrap_mut_1_p : Stdlib.Float.t = x in
    if Windtrap_mut_________fixture_lost_ari_pos___ml.___windtrap_armed___ 1
    then __windtrap_mut_1_p
    else -. __windtrap_mut_1_p
  let diff a b =
    a -
      (let __windtrap_mut_2_p : Stdlib.Int.t = b in
       if Windtrap_mut_________fixture_lost_ari_pos___ml.___windtrap_armed___ 2
       then __windtrap_mut_2_p
       else - __windtrap_mut_2_p)

  $ mut --impl ./fixture_lost_left.ml | ../elide.exe
  mutation sites of "./fixture_lost_left.ml" in Windtrap_mut_________fixture_lost_left___ml, with type ints:
    0: 6:16-6:18 "pos" "- x" -> "x"
    1: 7:14-7:19 "sub" "a + b" -> "a - b"
  let (@) a b = a ^ b
  let joined a b = a @ b
  let negated x =
    let __windtrap_mut_0_p : Stdlib.Int.t = x in
    if Windtrap_mut_________fixture_lost_left___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_p
    else - __windtrap_mut_0_p
  let sum a b =
    let (__windtrap_mut_1_l, __windtrap_mut_1_r) =
      ((a, b) : Windtrap_mut_________fixture_lost_left___ml.ints) in
    if Windtrap_mut_________fixture_lost_left___ml.___windtrap_armed___ 1
    then __windtrap_mut_1_l - __windtrap_mut_1_r
    else __windtrap_mut_1_l + __windtrap_mut_1_r

  $ mut --impl ./fixture_lost_ret.ml | ../elide.exe
  type found =
    | Some of int 
    | Missing 
  let found n = Some n
  let push x xs = x :: xs
  $ mut --impl ./fixture_lost_ret_cons.ml | ../elide.exe
  mutation sites of "./fixture_lost_ret_cons.ml" in Windtrap_mut_________fixture_lost_ret_cons___ml, with type ints:
    0: 9:14-9:19 "sub" "a + b" -> "a - b"
  type pair =
    | (::) of int * string 
  let pair n s = n :: s
  let found n = Some n
  let sum a b =
    let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
      ((a, b) : Windtrap_mut_________fixture_lost_ret_cons___ml.ints) in
    if Windtrap_mut_________fixture_lost_ret_cons___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_l - __windtrap_mut_0_r
    else __windtrap_mut_0_l + __windtrap_mut_0_r
  $ mut --impl ./fixture_lost_ret_none.ml | ../elide.exe
  mutation sites of "./fixture_lost_ret_none.ml" in Windtrap_mut_________fixture_lost_ret_none___ml, with type ints:
    0: 9:14-9:19 "sub" "a + b" -> "a - b"
  type outcome =
    | None 
    | Other 
  let found n = Some n
  let push x xs = x :: xs
  let sum a b =
    let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
      ((a, b) : Windtrap_mut_________fixture_lost_ret_none___ml.ints) in
    if Windtrap_mut_________fixture_lost_ret_none___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_l - __windtrap_mut_0_r
    else __windtrap_mut_0_l + __windtrap_mut_0_r
  $ mut --impl ./fixture_lost_ret_extension.ml | ../elide.exe
  mutation sites of "./fixture_lost_ret_extension.ml" in Windtrap_mut_________fixture_lost_ret_extension___ml, with type ints:
    0: 8:14-8:19 "sub" "a + b" -> "a - b"
  type e = ..
  type e +=  
    | None 
  let found n = Some n
  let sum a b =
    let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
      ((a, b) : Windtrap_mut_________fixture_lost_ret_extension___ml.ints) in
    if
      Windtrap_mut_________fixture_lost_ret_extension___ml.___windtrap_armed___
        0
    then __windtrap_mut_0_l - __windtrap_mut_0_r
    else __windtrap_mut_0_l + __windtrap_mut_0_r

  $ mut --impl ./fixture_neg.ml | ../elide.exe
  mutation sites of "./fixture_neg.ml" in Windtrap_mut_________fixture_neg___ml:
    0: 8:23-8:27 "not" "flag" -> "not flag"
    1: 9:33-9:50 "del" "print_string \"on\"" -> "()"
    2: 9:23-9:27 "not" "flag" -> "not flag"
    3: 13:4-13:11 "del" "step ()" -> "()"
    4: 12:8-12:16 "not" "ready ()" -> "not (ready ())"
    5: 16:39-16:42 "not" "p y" -> "not (p y)"
    6: 20:55-20:56 "int" "0" -> "1"
    7: 20:48-20:49 "int" "1" -> "0"
    8: 20:20-20:42 "not" "if a then b else false" -> "not (if a then b else false)"
    9: 20:37-20:42 "bool" "false" -> "true"
    10: 20:23-20:24 "not" "a" -> "not a"
  let pick flag x y =
    if
      let __windtrap_mut_0_p : Stdlib.Bool.t = flag in
      (if Windtrap_mut_________fixture_neg___ml.___windtrap_armed___ 0
       then Stdlib.not __windtrap_mut_0_p
       else __windtrap_mut_0_p)
    then x
    else y
  let announce flag =
    if
      let __windtrap_mut_2_p : Stdlib.Bool.t = flag in
      (if Windtrap_mut_________fixture_neg___ml.___windtrap_armed___ 2
       then Stdlib.not __windtrap_mut_2_p
       else __windtrap_mut_2_p)
    then
      (if Windtrap_mut_________fixture_neg___ml.___windtrap_armed___ 1
       then ((())[@ocaml.warning "-41-42"])
       else print_string "on")
  let drain ready step =
    while
      let __windtrap_mut_4_p : Stdlib.Bool.t = ready () in
      if Windtrap_mut_________fixture_neg___ml.___windtrap_armed___ 4
      then Stdlib.not __windtrap_mut_4_p
      else __windtrap_mut_4_p do
      (if Windtrap_mut_________fixture_neg___ml.___windtrap_armed___ 3
       then ((())[@ocaml.warning "-41-42"])
       else (step (); ((())[@ocaml.warning "-41-42"])) : Stdlib.Unit.t)
      done
  let classify p x =
    match x with
    | y when
        let __windtrap_mut_5_p : Stdlib.Bool.t = p y in
        if Windtrap_mut_________fixture_neg___ml.___windtrap_armed___ 5
        then Stdlib.not __windtrap_mut_5_p
        else __windtrap_mut_5_p -> "yes"
    | _ -> "no"
  let nested a b =
    if
      let __windtrap_mut_8_p : Stdlib.Bool.t =
        if
          let __windtrap_mut_10_p : Stdlib.Bool.t = a in
          (if Windtrap_mut_________fixture_neg___ml.___windtrap_armed___ 10
           then Stdlib.not __windtrap_mut_10_p
           else __windtrap_mut_10_p)
        then b
        else
          if Windtrap_mut_________fixture_neg___ml.___windtrap_armed___ 9
          then true
          else false in
      (if Windtrap_mut_________fixture_neg___ml.___windtrap_armed___ 8
       then Stdlib.not __windtrap_mut_8_p
       else __windtrap_mut_8_p)
    then
      (if Windtrap_mut_________fixture_neg___ml.___windtrap_armed___ 7
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_neg___ml.___windtrap_armed___ 6
      then 1
      else 0

  $ mut --impl ./fixture_nesting.ml | ../elide.exe
  mutation sites of "./fixture_nesting.ml" in Windtrap_mut_________fixture_nesting___ml, with type 'a operands:
    0: 6:23-6:29 "or" "b && c" -> "b || c"
    1: 7:18-7:26 "or" "a && b" -> "a || b"
    2: 8:30-8:38 "and" "c || d" -> "c && d"
    3: 11:38-11:39 "int" "0" -> "1"
    4: 11:31-11:32 "int" "1" -> "0"
    5: 11:20-11:25 "le" "a < b" -> "a <= b"
    6: 12:39-12:40 "int" "0" -> "1"
    7: 12:32-12:33 "int" "1" -> "0"
    8: 12:20-12:26 "or" "a && b" -> "a || b"
    9: 13:32-13:33 "int" "0" -> "1"
    10: 13:25-13:26 "int" "1" -> "0"
    11: 13:18-13:19 "not" "a" -> "not a"
  let chain a b c =
    a &&
      (let __windtrap_mut_0_p : Stdlib.Bool.t = b in
       (if
          Stdlib.(<>) __windtrap_mut_0_p
            (Windtrap_mut_________fixture_nesting___ml.___windtrap_armed___ 0)
        then c
        else __windtrap_mut_0_p : Stdlib.Bool.t))
  let mixed a b c =
    (let __windtrap_mut_1_p : Stdlib.Bool.t = a in
     (if
        Stdlib.(<>) __windtrap_mut_1_p
          (Windtrap_mut_________fixture_nesting___ml.___windtrap_armed___ 1)
      then b
      else __windtrap_mut_1_p : Stdlib.Bool.t)) || c
  let deep a b c d =
    a ||
      (b &&
         (let __windtrap_mut_2_p : Stdlib.Bool.t = c in
          (if
             Stdlib.(=) __windtrap_mut_2_p
               (Windtrap_mut_________fixture_nesting___ml.___windtrap_armed___
                  2)
           then d
           else __windtrap_mut_2_p : Stdlib.Bool.t)))
  let by_cmp a b =
    if
      let (__windtrap_mut_5_l, __windtrap_mut_5_r) =
        ((a, b) : _ Windtrap_mut_________fixture_nesting___ml.operands) in
      (if Windtrap_mut_________fixture_nesting___ml.___windtrap_armed___ 5
       then Stdlib.not (__windtrap_mut_5_r < __windtrap_mut_5_l)
       else __windtrap_mut_5_l < __windtrap_mut_5_r)
    then
      (if Windtrap_mut_________fixture_nesting___ml.___windtrap_armed___ 4
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_nesting___ml.___windtrap_armed___ 3
      then 1
      else 0
  let by_con a b =
    if
      let __windtrap_mut_8_p : Stdlib.Bool.t = a in
      ((if
          Stdlib.(<>) __windtrap_mut_8_p
            (Windtrap_mut_________fixture_nesting___ml.___windtrap_armed___ 8)
        then b
        else __windtrap_mut_8_p) : Stdlib.Bool.t)
    then
      (if Windtrap_mut_________fixture_nesting___ml.___windtrap_armed___ 7
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_nesting___ml.___windtrap_armed___ 6
      then 1
      else 0
  let by_neg a =
    if
      let __windtrap_mut_11_p : Stdlib.Bool.t = a in
      (if Windtrap_mut_________fixture_nesting___ml.___windtrap_armed___ 11
       then Stdlib.not __windtrap_mut_11_p
       else __windtrap_mut_11_p)
    then
      (if Windtrap_mut_________fixture_nesting___ml.___windtrap_armed___ 10
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_nesting___ml.___windtrap_armed___ 9
      then 1
      else 0

  $ mut --impl ./fixture_off.ml | ../elide.exe
  mutation sites of "./fixture_off.ml" in Windtrap_mut_________fixture_off___ml, with type ints:
    0: 10:7-10:9 "int" "16" -> "17"
    1: 9:5-9:16 "ge" "want > 16" -> "want >= 16", dismissed "both arms yield 16 at the boundary"
    2: 12:54-12:55 "int" "0" -> "1"
    3: 12:47-12:48 "int" "1" -> "0"
    4: 12:19-12:27 "or" "a && b" -> "a || b", dismissed ""
    5: 26:18-26:23 "sub" "a + b" -> "a - b"
  let cap want =
    if ((want > 16)[@mutate off "both arms yield 16 at the boundary"])
    then want
    else
      if Windtrap_mut_________fixture_off___ml.___windtrap_armed___ 0
      then 17
      else 16
  let plain a b =
    if ((a && b)[@mutate off])
    then
      (if Windtrap_mut_________fixture_off___ml.___windtrap_armed___ 3
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_off___ml.___windtrap_armed___ 2
      then 1
      else 0
  let sum a b = a + b[@@mutate off]
  module Hidden = struct let diff a b = a - b end[@@mutate off]
  [@@@mutate off]
  let suppressed a b = a + b
  [@@@mutate on]
  let visible a b =
    let (__windtrap_mut_5_l, __windtrap_mut_5_r) =
      ((a, b) : Windtrap_mut_________fixture_off___ml.ints) in
    if Windtrap_mut_________fixture_off___ml.___windtrap_armed___ 5
    then __windtrap_mut_5_l - __windtrap_mut_5_r
    else __windtrap_mut_5_l + __windtrap_mut_5_r

  $ mut --impl ./fixture_off_edges.ml | ../elide.exe
  mutation sites of "./fixture_off_edges.ml" in Windtrap_mut_________fixture_off_edges___ml, with type ints:
    0: 19:7-19:9 "int" "16" -> "17"
    1: 15:4-15:15 "ge" "want > 16" -> "want >= 16", dismissed "a \"quoted\" reason,\nspanning lines \\ containing a backslash"
    2: 30:10-30:15 "sub" "a + b" -> "a - b"
    3: 39:16-39:21 "sub" "a + b" -> "a - b"
  let quoted want =
    if ((want > 16)
      [@mutate
        off "a \"quoted\" reason,\nspanning lines \\ containing a backslash"])
    then want
    else
      if Windtrap_mut_________fixture_off_edges___ml.___windtrap_armed___ 0
      then 17
      else 16
  let coarse a b = ((match a with | 0 -> b | n -> n + b)
    [@mutate off "not a site"])
  let local a b =
    let s =
      let (__windtrap_mut_2_l, __windtrap_mut_2_r) =
        ((a, b) : Windtrap_mut_________fixture_off_edges___ml.ints) in
      if Windtrap_mut_________fixture_off_edges___ml.___windtrap_armed___ 2
      then __windtrap_mut_2_l - __windtrap_mut_2_r
      else __windtrap_mut_2_l + __windtrap_mut_2_r[@@mutate off "ignored here"] in
    s
  type t = int[@@mutate off]
  let after a b =
    let (__windtrap_mut_3_l, __windtrap_mut_3_r) =
      ((a, b) : Windtrap_mut_________fixture_off_edges___ml.ints) in
    if Windtrap_mut_________fixture_off_edges___ml.___windtrap_armed___ 3
    then __windtrap_mut_3_l - __windtrap_mut_3_r
    else __windtrap_mut_3_l + __windtrap_mut_3_r

  $ mut --impl ./fixture_off_structure.ml | ../elide.exe
  mutation sites of "./fixture_off_structure.ml" in Windtrap_mut_________fixture_off_structure___ml, with type ints:
    0: 16:12-16:17 "add" "x - 1" -> "x + 1"
    1: 41:23-41:28 "sub" "a + b" -> "a - b"
    2: 48:14-48:19 "sub" "a + b" -> "a - b"
  module rec Dark:sig val f : int -> int end = struct let f n = n + 1 end
  [@@mutate off]
  
  let local n =
    let h x =
      let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
        ((x, 1) : Windtrap_mut_________fixture_off_structure___ml.ints) in
      if Windtrap_mut_________fixture_off_structure___ml.___windtrap_armed___ 0
      then __windtrap_mut_0_l + __windtrap_mut_0_r
      else __windtrap_mut_0_l - __windtrap_mut_0_r[@@mutate bogus] in
    h n
  type t = int[@@mutate bogus]
  let reasoned a b = a + b[@@mutate off "binding reason"]
  [@@@mutate off "region reason"]
  let in_region a b = a - b
  [@@@mutate on]
  [@@@mutate off]
  module Inherits =
    struct
      let dark a b = a + b
      [@@@mutate on]
      let lit_inside a b =
        let (__windtrap_mut_1_l, __windtrap_mut_1_r) =
          ((a, b) : Windtrap_mut_________fixture_off_structure___ml.ints) in
        if
          Windtrap_mut_________fixture_off_structure___ml.___windtrap_armed___
            1
        then __windtrap_mut_1_l - __windtrap_mut_1_r
        else __windtrap_mut_1_l + __windtrap_mut_1_r
    end
  let still_dark a b = a + b
  [@@@mutate on]
  let lit a b =
    let (__windtrap_mut_2_l, __windtrap_mut_2_r) =
      ((a, b) : Windtrap_mut_________fixture_off_structure___ml.ints) in
    if Windtrap_mut_________fixture_off_structure___ml.___windtrap_armed___ 2
    then __windtrap_mut_2_l - __windtrap_mut_2_r
    else __windtrap_mut_2_l + __windtrap_mut_2_r

  $ mut --impl ./fixture_off_unclosed.ml | ../elide.exe
  mutation sites of "./fixture_off_unclosed.ml" in Windtrap_mut_________fixture_off_unclosed___ml, with type ints:
    0: 17:18-17:23 "sub" "a + b" -> "a - b"
  module Quiet = struct [@@@mutate off]
                        let hidden a b = a + b end
  let visible a b =
    let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
      ((a, b) : Windtrap_mut_________fixture_off_unclosed___ml.ints) in
    if Windtrap_mut_________fixture_off_unclosed___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_l - __windtrap_mut_0_r
    else __windtrap_mut_0_l + __windtrap_mut_0_r
  [@@@mutate off]
  let suppressed a b = a + b
  let also_suppressed a b = if a && b then 1 else 0

  $ mut --impl ./fixture_payloads.ml | ../elide.exe
  mutation sites of "./fixture_payloads.ml" in Windtrap_mut_________fixture_payloads___ml, with type ints:
    0: 6:18-6:23 "sub" "a + b" -> "a - b"
  let extended = [%ext a + b]
  let attributed = ((0)[@attr a + b])
  let written a b =
    let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
      ((a, b) : Windtrap_mut_________fixture_payloads___ml.ints) in
    if Windtrap_mut_________fixture_payloads___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_l - __windtrap_mut_0_r
    else __windtrap_mut_0_l + __windtrap_mut_0_r

  $ sites --impl ./fixture_scope.ml
    0: 16:17-16:22 "div" "a * b" -> "a / b"
    1: 21:19-21:28 "tail" "[a * b]" -> "[]"
    2: 47:19-47:28 "sub" "(a * b) + x" -> "(a * b) - x"
    3: 56:23-56:28 "div" "a * b" -> "a / b"
    4: 60:27-60:32 "div" "a * b" -> "a / b"
    5: 75:25-75:34 "sub" "(a * b) + x" -> "(a * b) - x"
    6: 88:28-88:41 "sub" "((a * b) + y) + z" -> "((a * b) + y) - z"
    7: 88:28-88:33 "div" "a * b" -> "a / b"
    8: 97:21-97:30 "sub" "a + (b * c)" -> "a - (b * c)"

  $ mut --impl ./fixture_counter_scope.ml | ../elide.exe
  mutation sites of "./fixture_counter_scope.ml" in Windtrap_mut_________fixture_counter_scope___ml:
    0: 11:30-11:36 "decr" "incr a" -> "decr a"
    1: 16:2-16:8 "decr" "incr a" -> "decr a"
    2: 21:16-21:22 "decr" "incr a" -> "decr a"
    3: 27:13-27:19 "decr" "incr r" -> "decr r"
  module Opened =
    struct
      open Atomic
      let up (a : int Atomic.t) =
        if
          Windtrap_mut_________fixture_counter_scope___ml.___windtrap_armed___
            0
        then decr a
        else incr a
    end
  let let_opened (a : int Atomic.t) =
    let open Atomic in
      if Windtrap_mut_________fixture_counter_scope___ml.___windtrap_armed___ 1
      then decr a
      else incr a
  class let_opened_class (a : int Atomic.t) =
    let open Atomic in
      object
        method up =
          if
            Windtrap_mut_________fixture_counter_scope___ml.___windtrap_armed___
              2
          then decr a
          else incr a
      end
  module Included =
    struct
      include Int
      let up r =
        if
          Windtrap_mut_________fixture_counter_scope___ml.___windtrap_armed___
            3
        then decr r
        else incr r
    end
  let under_open r = let open Counters in incr r
  let under_path r = let open Counters in incr r
  module Under_include = struct include Counters
                                let up r = incr r end
  class under_class r = let open Counters in object method up = incr r end
  module Structure_open = struct open Counters
                                 let up r = incr r end
  let float_array r = let open Float.Array in incr r
  let stdlib_atomic (a : int Atomic.t) = let open Stdlib.Atomic in incr a
  module type S  = sig type t end
  let unseen r ((module C)  : (module S)) = let open C in incr r
  let first_class r m = let open (val (m : (module S))) in incr r

  $ mut --impl ./fixture_counter_declared.ml | ../elide.exe
  mutation sites of "./fixture_counter_declared.ml" in Windtrap_mut_________fixture_counter_declared___ml:
    0: 15:13-15:19 "decr" "incr r" -> "decr r"
  module Atomic = struct type t = int ref
                         let make n : t= ref n end
  module Int = struct  end
  let atomic (a : int Stdlib.Atomic.t) = Atomic.incr a
  let opened r = let open Int in incr r
  let bare r =
    if
      Windtrap_mut_________fixture_counter_declared___ml.___windtrap_armed___ 0
    then decr r
    else incr r

  $ mut --impl ./fixture_counter_inherit.ml | ../elide.exe
  mutation sites of "./fixture_counter_inherit.ml" in Windtrap_mut_________fixture_counter_inherit___ml:
    0: 21:16-21:22 "decr" "incr r" -> "decr r"
  class base = object  end
  class child r = object inherit  base method up = incr r end
  let immediate r = object inherit  base method up = incr r end
  class plain r =
    object
      method up =
        if
          Windtrap_mut_________fixture_counter_inherit___ml.___windtrap_armed___
            0
        then decr r
        else incr r
    end

  $ mut --impl ./fixture_shadow.ml | ../elide.exe
  mutation sites of "./fixture_shadow.ml" in Windtrap_mut_________fixture_shadow___ml, with type 'a operands:
    0: 16:39-16:40 "int" "0" -> "1"
    1: 16:32-16:33 "int" "1" -> "0"
    2: 16:21-16:26 "le" "a < b" -> "a <= b"
    3: 17:15-17:21 "or" "a && b" -> "a || b"
  module Vec =
    struct
      type t = {
        x: int ;
        y: int }
      let (+) a b = { x = (a.x + b.x); y = (a.y + b.y) }
    end
  let move a b = Vec.(+) a b
  let ordered a b =
    if
      let (__windtrap_mut_2_l, __windtrap_mut_2_r) =
        ((a, b) : _ Windtrap_mut_________fixture_shadow___ml.operands) in
      (if Windtrap_mut_________fixture_shadow___ml.___windtrap_armed___ 2
       then Stdlib.not (__windtrap_mut_2_r < __windtrap_mut_2_l)
       else __windtrap_mut_2_l < __windtrap_mut_2_r)
    then
      (if Windtrap_mut_________fixture_shadow___ml.___windtrap_armed___ 1
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_shadow___ml.___windtrap_armed___ 0
      then 1
      else 0
  let both a b =
    let __windtrap_mut_3_p : Stdlib.Bool.t = a in
    (if
       Stdlib.(<>) __windtrap_mut_3_p
         (Windtrap_mut_________fixture_shadow___ml.___windtrap_armed___ 3)
     then b
     else __windtrap_mut_3_p : Stdlib.Bool.t)
  let untouched a b = a - b

  $ mut --impl ./fixture_texts.ml | ../elide.exe
  mutation sites of "./fixture_texts.ml" in Windtrap_mut_________fixture_texts___ml, with type 'a operands, type ints:
    0: 6:42-6:43 "int" "0" -> "1"
    1: 6:35-6:36 "int" "1" -> "0"
    2: 6:18-6:29 "neq" "s = \"a b\"" -> "s <> \"a b\""
    3: 10:15-10:22 "sub" "a + b" -> "a - b"
    4: 11:50-11:51 "int" "0" -> "1"
    5: 11:43-11:44 "int" "1" -> "0"
    6: 11:22-11:29 "le" "a < b" -> "a <= b"
  let spaced s =
    if
      let __windtrap_mut_2_p : Stdlib.Bool.t = s = "a   b" in
      (if Windtrap_mut_________fixture_texts___ml.___windtrap_armed___ 2
       then Stdlib.not __windtrap_mut_2_p
       else __windtrap_mut_2_p)
    then
      (if Windtrap_mut_________fixture_texts___ml.___windtrap_armed___ 1
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_texts___ml.___windtrap_armed___ 0
      then 1
      else 0
  let kept a b =
    let (__windtrap_mut_3_l, __windtrap_mut_3_r) =
      ((a, b) : Windtrap_mut_________fixture_texts___ml.ints) in
    if Windtrap_mut_________fixture_texts___ml.___windtrap_armed___ 3
    then __windtrap_mut_3_l - __windtrap_mut_3_r
    else ((__windtrap_mut_3_l + __windtrap_mut_3_r)[@kept ])
  let kept_cmp a b =
    if
      let (__windtrap_mut_6_l, __windtrap_mut_6_r) =
        ((a, b) : _ Windtrap_mut_________fixture_texts___ml.operands) in
      (if Windtrap_mut_________fixture_texts___ml.___windtrap_armed___ 6
       then Stdlib.not (__windtrap_mut_6_r < __windtrap_mut_6_l)
       else ((__windtrap_mut_6_l < __windtrap_mut_6_r)[@kept ]))
    then
      (if Windtrap_mut_________fixture_texts___ml.___windtrap_armed___ 5
       then 0
       else 1)
    else
      if Windtrap_mut_________fixture_texts___ml.___windtrap_armed___ 4
      then 1
      else 0

Over code a deriver generated, for which generated.ml stands in:

  $ ../pp.exe -apply windtrap_test_generated,windtrap_mutate --impl ./fixture_generated.ml | ../elide.exe
  mutation sites of "./fixture_generated.ml" in Windtrap_mut_________fixture_generated___ml, with type ints:
    0: 6:18-6:23 "add" "a - b" -> "a + b"
    1: 11:17-11:28 "div" "a * (a + b)" -> "a / (a + b)"
    2: 11:21-11:28 "sub" "a + b" -> "a - b"
  let generated a b = ((a + b)[@generated ])
  let written a b =
    let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
      ((a, b) : Windtrap_mut_________fixture_generated___ml.ints) in
    if Windtrap_mut_________fixture_generated___ml.___windtrap_armed___ 0
    then __windtrap_mut_0_l + __windtrap_mut_0_r
    else __windtrap_mut_0_l - __windtrap_mut_0_r
  let copied a b =
    let (__windtrap_mut_1_l, __windtrap_mut_1_r) =
      ((a,
         (let (__windtrap_mut_2_l, __windtrap_mut_2_r) =
            ((a, b) : Windtrap_mut_________fixture_generated___ml.ints) in
          if Windtrap_mut_________fixture_generated___ml.___windtrap_armed___ 2
          then __windtrap_mut_2_l - __windtrap_mut_2_r
          else __windtrap_mut_2_l + __windtrap_mut_2_r)) : Windtrap_mut_________fixture_generated___ml.ints) in
    if Windtrap_mut_________fixture_generated___ml.___windtrap_armed___ 1
    then __windtrap_mut_1_l / __windtrap_mut_1_r
    else __windtrap_mut_1_l * __windtrap_mut_1_r[@@duplicate ]
  let copied a b = a * (a + b)[@@duplicate ]

  $ ../pp.exe -apply windtrap_test_generated,windtrap_mutate --impl ./fixture_generated_chain.ml | ../elide.exe
  mutation sites of "./fixture_generated_chain.ml" in Windtrap_mut_________fixture_generated_chain___ml, with type ints:
    0: 6:23-6:34 "sub" "(a + b) + c" -> "(a + b) - c"
  let generated a b c = (((a + b) + c)[@generated ])
  let copied f a b c =
    f
      (let (__windtrap_mut_0_l, __windtrap_mut_0_r) =
         (((a + b), c) : Windtrap_mut_________fixture_generated_chain___ml.ints) in
       if
         Windtrap_mut_________fixture_generated_chain___ml.___windtrap_armed___
           0
       then __windtrap_mut_0_l - __windtrap_mut_0_r
       else __windtrap_mut_0_l + __windtrap_mut_0_r)[@@duplicate ]
  let copied f a b c = f ((a + b) + c)[@@duplicate ]

Over a file the coverage rewriter ran on first. pp.exe runs the mutation
rewriter first whatever order -apply names, so this order has its own
driver, coverage_first.exe:

  $ ../coverage_first.exe -apply windtrap_coverage,windtrap_mutate --impl ./fixture_visits.ml | ../elide.exe
  mutation sites of "./fixture_visits.ml" in Windtrap_mut_________fixture_visits___ml, with type 'a operands:
    0: 7:22-7:23 "not" "b" -> "not b"
    1: 7:17-7:18 "not" "a" -> "not a"
    2: 10:40-10:41 "int" "0" -> "1"
    3: 10:33-10:34 "int" "1" -> "0"
    4: 10:18-10:27 "le" "(___windtrap_post_visit___ 2 (f x)) < (___windtrap_post_visit___ 3 (g x))" -> "(___windtrap_post_visit___ 2 (f x)) <= (___windtrap_post_visit___ 3 (g x))"
    5: 14:24-14:25 "int" "2" -> "3"
  coverage points of "./fixture_visits.ml" in Windtrap_cov_________fixture_visits___ml, with ___windtrap_post_visit___:
    0: 262-263
    1: 267-268
    2: 362-365
    3: 368-371
    4: 384-385
    5: 377-378
    6: 359-385
    7: 519-522
    8: 612-614
    9: 634-639
    10: 656-662
  let either a b =
    ___windtrap_visit___ 0;
    if
      (let __windtrap_mut_1_p : Stdlib.Bool.t = a in
       if Windtrap_mut_________fixture_visits___ml.___windtrap_armed___ 1
       then Stdlib.not __windtrap_mut_1_p
       else __windtrap_mut_1_p)
    then (___windtrap_visit___ 0; true)
    else
      if
        (let __windtrap_mut_0_p : Stdlib.Bool.t = b in
         if Windtrap_mut_________fixture_visits___ml.___windtrap_armed___ 0
         then Stdlib.not __windtrap_mut_0_p
         else __windtrap_mut_0_p)
      then (___windtrap_visit___ 1; true)
      else false
  let lt f g x =
    ___windtrap_visit___ 6;
    if
      (let (__windtrap_mut_4_l, __windtrap_mut_4_r) =
         (((___windtrap_post_visit___ 2 (f x)),
            (___windtrap_post_visit___ 3 (g x))) : _
                                                     Windtrap_mut_________fixture_visits___ml.operands) in
       if Windtrap_mut_________fixture_visits___ml.___windtrap_armed___ 4
       then Stdlib.not (__windtrap_mut_4_r < __windtrap_mut_4_l)
       else __windtrap_mut_4_l < __windtrap_mut_4_r)
    then
      (___windtrap_visit___ 5;
       if Windtrap_mut_________fixture_visits___ml.___windtrap_armed___ 3
       then 0
       else 1)
    else
      (___windtrap_visit___ 4;
       if Windtrap_mut_________fixture_visits___ml.___windtrap_armed___ 2
       then 1
       else 0)
  let product f x =
    ___windtrap_visit___ 7;
    (___windtrap_post_visit___ 7 (f x)) *
      (if Windtrap_mut_________fixture_visits___ml.___windtrap_armed___ 5
       then 3
       else 2)
  let negated x = ___windtrap_visit___ 8; - x
  let appended a b = ___windtrap_visit___ 9; a @ b
  let counted r = ___windtrap_visit___ 10; incr r

A file under an input name that is not a source file's is returned as
parsed:

  $ for name in //toplevel// '(stdin)' lib/.ocamlinit lib/topfind; do
  >   mut -loc-filename "$name" --impl ./fixture_input_name.ml
  > done
  let sign n = if n > 0 then 1 else 0
  let sign n = if n > 0 then 1 else 0
  let sign n = if n > 0 then 1 else 0
  let sign n = if n > 0 then 1 else 0

A refusal is an error located at the attribute, and the driver exits 1:

  $ mut --impl ./reject_bad_payload.ml
  File "./reject_bad_payload.ml", line 1, characters 18-33:
  1 | let f n = (n + 1) [@mutate bogus]
                        ^^^^^^^^^^^^^^^
  Error: Bad payload in mutate attribute.
  [1]

  $ mut --impl ./reject_double_off.ml
  File "./reject_double_off.ml", line 5, characters 0-15:
  5 | [@@@mutate off]
      ^^^^^^^^^^^^^^^
  Error: Mutation is already off.
  [1]

  $ mut --impl ./reject_empty_payload.ml
  File "./reject_empty_payload.ml", line 1, characters 18-27:
  1 | let f n = (n + 1) [@mutate]
                        ^^^^^^^^^
  Error: Bad payload in mutate attribute.
  [1]

  $ mut --impl ./reject_exclude_file_binding.ml
  File "./reject_exclude_file_binding.ml", line 1, characters 16-39:
  1 | let f n = n + 1 [@@mutate exclude_file]
                      ^^^^^^^^^^^^^^^^^^^^^^^
  Error: mutate exclude_file is not allowed here.
  [1]

  $ mut --impl ./reject_exclude_file_expr.ml
  File "./reject_exclude_file_expr.ml", line 1, characters 18-40:
  1 | let f n = (n + 1) [@mutate exclude_file]
                        ^^^^^^^^^^^^^^^^^^^^^^
  Error: mutate exclude_file is not allowed here.
  [1]

  $ mut --impl ./reject_misplaced_exclude_file.ml
  File "./reject_misplaced_exclude_file.ml", line 2, characters 2-26:
  2 |   [@@@mutate exclude_file]
        ^^^^^^^^^^^^^^^^^^^^^^^^
  Error: mutate exclude_file is not allowed here.
  [1]

  $ mut --impl ./reject_misplaced_on.ml
  File "./reject_misplaced_on.ml", line 1, characters 18-30:
  1 | let f n = (n + 1) [@mutate on]
                        ^^^^^^^^^^^^
  Error: mutate on is not allowed here.
  [1]

  $ mut --impl ./reject_off_number.ml
  File "./reject_off_number.ml", line 1, characters 18-34:
  1 | let f n = (n + 1) [@mutate off 42]
                        ^^^^^^^^^^^^^^^^
  Error: Bad payload in mutate attribute.
  [1]

  $ mut --impl ./reject_off_rewrite.ml
  File "./reject_off_rewrite.ml", line 3, characters 18-51:
  3 | let f n = (n + 1) [@mutate off sub "equal at zero"]
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: Bad payload in mutate attribute.
  [1]

  $ mut --impl ./reject_off_two_reasons.ml
  File "./reject_off_two_reasons.ml", line 1, characters 18-39:
  1 | let f n = (n + 1) [@mutate off "a" "b"]
                        ^^^^^^^^^^^^^^^^^^^^^
  Error: Bad payload in mutate attribute.
  [1]

  $ mut --impl ./reject_on_assert.ml
  File "./reject_on_assert.ml", line 1, characters 19-31:
  1 | let f x = assert x [@mutate on]
                         ^^^^^^^^^^^^
  Error: mutate on is not allowed here.
  [1]

  $ mut --impl ./reject_on_binding.ml
  File "./reject_on_binding.ml", line 1, characters 16-29:
  1 | let f n = n + 1 [@@mutate on]
                      ^^^^^^^^^^^^^
  Error: mutate on is not allowed here.
  [1]

  $ mut --impl ./reject_on_outside.ml
  File "./reject_on_outside.ml", line 3, characters 0-14:
  3 | [@@@mutate on]
      ^^^^^^^^^^^^^^
  Error: Mutation is already on.
  [1]
