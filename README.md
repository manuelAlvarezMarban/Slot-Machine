# Slot-Machine
Slot Machine hardware implementation with LFSR for random slots.

It uses a [Linear Feedback Shift Register](https://es.wikipedia.org/wiki/LFSR) with 64 degree polynomial and one seed in order to random slots generation. 
Each slot is represented by 4 bits vector (BCD).

The system consists on one RandomGeneration module which uses the LFSR, one arithmetic module for prize calculating and the
Slot Machine managed by different states.

First we need to init the Machine (nReset - active low), then we can play by inserting new credit (newCredit = 1). 
The prizes and their several slots combination are:

| Slot | Prize Type | Prize        |
|------|------------|--------------|
| 777  | MAX        | 225 €        |
| 111  | HI         | 25 €         |
| 222  | HI         | 25 €         |
| 333  | HI         | 25 €         |
| 555  | HI         | 25 €         |
| x77  | NEAR       | 10 €         |
| 77x  | NEAR       | 10 €         |
| xx1  | LO         | 1 € (refund) |
| xx3  | LO         | 1 € (refund) |
| xx5  | LO         | 1 € (refund) |
| xx7  | NEAR-LO    | 1 € (refund) |
| 0xx  | BANK       | No Prize     |
| x0x  | BANK       | No Prize     |
| xx0  | BANK       | No Prize     |

Each bet (credit) is 1 €. After endPlay = 1 the slots combination and prize earned could be seen. If we win, pay must be '1' before play again.
If we gain the refund, no new credits must be inserted to play again.


In testbench, we play 20 times. Try it!: https://www.edaplayground.com/x/3CcF
