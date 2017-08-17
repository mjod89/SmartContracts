// Dapple test of the three contracts



pragma solidity ^0.4.4;
import 'dapple/test.sol';
import 'LocalCrypto.sol';
import 'prisoners.sol';
import 'Colluders.sol';
import 'Traitors.sol';


contract secondAccount{
prisoners pr;
LocalCrypto conn;
Colluders co;
Traitors tr;

    function secondAccount(prisoners _pr, LocalCrypto _conn, Colluders _co, Traitors _tr) {
        pr = _pr;
        conn = _conn;
        co = _co;
        tr = _tr;
    }

    /******************* Prisoners interface functions *********************/
    function callcreate(uint w, uint ch, uint d, uint T1, uint T2, uint T3) payable returns (bool){
      return pr.Create.value(msg.value)(w,ch,d,T1,T2,T3);
    }

    function callbid() payable returns (bool){
      return pr.Bid.value(msg.value)();
    }

    function calldeliver (uint[2]c, uint[2]t, uint n ) returns (bool){
      return pr.Deliver(c, t, n);
    }

    function callPay() returns (bool){
      return pr.Pay();
    }

    function calldispute(uint[2] c3, uint[2] t1, uint[2] _t1, uint[2] t2, uint[2] _t2, uint n1, uint _n1, uint n2, uint _n2) returns (uint){
        return pr.Dispute(c3,t1,_t1,t2,_t2,n1,_n1,n2,_n2);
    }

    function callTime() returns (bool){
     return pr.Timer();
    }

    /****************** Colluders interface functions *************************/
    function callcoC(uint[2] r1, uint[2] r2, uint _t, uint _b, uint t4, uint t5)payable returns(bool){
        return co.Create.value(msg.value)(r1,r2,_t,_b,t4,t5);
    }

    function calljoin() payable returns (bool){
      return co.Join.value(msg.value)();
    }

    function callColluderTimer() returns (bool){
      return co.Timer();
    }

    /****************** Traitors interface functions **************************/
    function callcreateT(address c) payable returns(bool){
      return tr.create.value(msg.value)(c);
    }

    function calljoinT() payable returns(bool){
      return tr.Join.value(msg.value)();
    }

    function calldeliverT(uint[2]c, uint[2]t, uint n ) returns (bool){
      return tr.Deliver(c, t, n);
    }

    function callcheck(uint[2] c1, uint[2] t, uint n, uint[2]t1, uint[2]t2, uint n1, uint n2) returns (uint){
      return tr.Check(c1, t, n, t1, t2, n1, n2);
    }

    function callChe() returns (bool){
      return tr.getChe();
    }


}


//test functions
contract Prisoners is Test {

    prisoners pr;
    LocalCrypto conn;
    Colluders co;
    Traitors tr;
    secondAccount con;
    Tester proxy_tester;

    secondAccount A;
    secondAccount B;
    secondAccount C;
    secondAccount D;

    uint public T1 = now + 10 minutes;
    uint public T2 = T1 + 10 minutes;
    uint public T3 = T1 + 15 minutes;
    uint public T4 = T1 + 5 minutes;
    uint public T5 = T1 + 20 minutes;

    uint public b1 = 23; uint public b2 = 21;
    uint public b4 = 23; uint public b3 = 23;

    uint[2] public t_3; uint[2] public _t_3; uint public n_3; uint public _n_3;

    uint public n1; uint public _n1;
    uint public n2; uint public _n2;
    uint public n; uint n3;

    uint[2] t; uint[2] t3;

    uint public r1 = 100792359988221257522464744073694181557998811287873941943642234039631667801743;

    uint public r2 = 73684597056470802520640839675442817373247702535850643999083350831860052477001;

    uint public r3 = 106554628258140934843991940734271727557510876833354296893443127816727132563840;

    uint public r4 = 50011181273477635355105934748199911221235256089199741271573814847024879061829;

    uint public r5 = 71802419974013591686591529237219896883303932349628173412957707346469215125624;

    uint public r6 = 1801119347122147381158502909947365828020117721497557484744596940174906898953;

    uint public r7 = 98038005178408974007512590727651089955354106077095278304532603697039577112780;


    function setUp() {
        pr = new prisoners();
        conn = new LocalCrypto();
        co = new Colluders(address(pr));
        tr = new Traitors(address(pr), address(co));

        proxy_tester = new Tester();

          B = new secondAccount(pr, conn, co, tr);

          C = new secondAccount(pr, conn, co, tr);

          A = new secondAccount(pr, conn, co, tr);

          D = new secondAccount(pr, conn, co, tr);
    }

    function setEligible() {
       address[] memory test = new address[](4);
       test[0] = address(A);
       test[1] = address(B);
       test[2] = address(C);
       test[3] = address(D);
       pr.setEligible(test);
   }

   /****************** PRISONERS CONTRACT TEST FUNCTIONS **********************/
  // Third testing case no one is cheating
  function testPrisonersWithNoCheat(){
          setEligible();
          A.callcreate.value(4)(1,2,4,T1,T2,T3);

          B.callbid.value(4)();
          C.callbid.value(4)();

          uint _b1 = 24; uint _b2 = 24; uint[2] memory t; uint n;
          uint[2] memory c1 = conn.createCommitment(r1,_b1);
          uint[2] memory c2 = conn.createCommitment(r2,_b2);
          (t,n) = conn.createEqualityProof(r1, r2, r3, c1, c2);

          B.calldeliver(c1, t, n);
          C.calldeliver(c2, t, n);

          A.callPay();
          assertEq(4, uint(pr.state()));

      }


  // Third testing case C2 is cheating
  function testPrisonersWithC2Cheat(){
          setEligible();
          A.callcreate.value(4)(1,2,4,T1,T2,T3);

          B.callbid.value(4)();
          C.callbid.value(4)();

          uint[2] memory t; uint n;
          uint[2] memory c1 = conn.createCommitment(r1,b1);
          uint[2] memory c2 = conn.createCommitment(r2,b2);
          (t,n) = conn.createEqualityProof(r1, r2, r3, c1, c2);

          B.calldeliver(c1, t, n);
          C.calldeliver(c2, t, n);

          A.callPay();
          assertEq(5, uint(pr.state()));


          uint[2] memory c3 = conn.createCommitment(r4,b3);

          // Create an equality proof
          uint[2] memory t1; uint[2] memory _t1;
          (t1,_t1,n1,_n1) = conn.createInequalityProof(b1, b3, r1, r4, r5, r6, c1, c3);

          uint[2] memory t2; uint[2] memory _t2;
          (t2,_t2,n2,_n2) = conn.createInequalityProof(b2, b3, r2, r4, r6, r7, c2, c3);

          assertEq(4, D.calldispute(c3,t1,_t1,t2,_t2,n1,_n1,n2,_n2));
      }

  //test timer function when T>=T1
  function testTimeIfTGreaterThanT1(){
     setEligible();
     uint T = now; uint _t1 = now ; uint _t2 = T;
     A.callcreate.value(4)(1,2,4,T, _t1, _t2);
     assertEq(1, uint (pr.state()));
     A.callTime();

     // test the balance after time passed T>=T1
     uint[4] memory balance = pr.getBalance();
     assertEq(4, balance[0]);
     assertEq(0, balance[1]);
     assertEq(0, balance[2]);
     assertEq(0, balance[3]);
   }

   // test timer function if T>=T2
  function testTimerTGreaterThanT2(){
        setEligible();
        A.callcreate.value(4)(1,2,4,T1, T2, T3);
        assertEq(1, uint (pr.state()));
        A.callTime();

        //test timer when T>=T2
        uint t1 = now + 2 minutes ;uint t2 = now ; uint t3 = now;
        A.callcreate.value(4)(1,2,4,t1, t2, t3);
        B.callbid.value(4)();
        C.callbid.value(4)();
        assertEq(2, uint(pr.state()));
        A.callTime();
        assertEq(3, uint(pr.state()));

  }

  // test Timer when T > T3
  function testTimerTGreaterThanT3(){

        setEligible();
        A.callcreate.value(4)(1,2,4,T1, T2, T3);
        assertEq(1, uint (pr.state()));
        A.callTime();

        //test timer when T>=T2
        uint t1 = now + 2 minutes ;uint t2 = T1 + 4 minutes ; uint t3 = now;
        A.callcreate.value(4)(1,2,4,t1, t2, t3);

        B.callbid.value(4)();
        C.callbid.value(4)();

        uint b1 = 24; uint b2 = 24; uint[2] memory t; uint n;
        uint[2] memory c1 = conn.createCommitment(r1,b1);
        uint[2] memory c2 = conn.createCommitment(r2,b2);
        (t,n) = conn.createEqualityProof(r1, r2, r3, c1, c2);

        B.calldeliver(c1, t, n);
        C.calldeliver(c2, t, n);
        assertEq(3, uint(pr.state()));

        A.callTime();
        assertEq(4, uint(pr.state()));

        // test the balance after time passed T>=T1
        uint[4] memory balance = pr.getBalance();
        assertEq(2, balance[0]);
        assertEq(5, balance[1]);
        assertEq(5, balance[2]);
        assertEq(0, balance[3]);
  }

  /****************** COLLUDERS CONTRACT TEST FUNCTIONS **********************/
  function testCreateColluder(){
      setEligible();

      uint[2] memory c1 = conn.createCommitment(r1,b1);
      uint[2] memory c2 = conn.createCommitment(r2,b2);
      uint[2] memory c3 = conn.createCommitment(r3,b3);

      A.callcreate.value(4)(1,2,2,T1,T2,T3);
      B.callbid.value(2)();
      C.callbid.value(2)();

      assertTrue(B.callcoC.value(5)(c1,c2,2,3,T4,T5));
      assertTrue(C.calljoin.value(5)());

  }

  // test not everyone can run the create function only C1 & C2.
  function testThrowNotEligibleToCollude(){
    setEligible();
    uint[2] memory c1 = conn.createCommitment(r1,b1);
    uint[2] memory c2 = conn.createCommitment(r2,b2);
    A.callcoC.value(5)(c1,c2,2,3,T4,T5);
    B.callcoC.value(1)(c1,c2,2,3,T4,T5);
  }

  // test the timer function when t > t4
  function testTimerColluderTGreaterThanT4(){
    setEligible();
    uint t1 = now  ; uint t2 = now + 20 seconds;
    uint t3 = now + 25 seconds; uint t4 = now ;
    uint t5 = now + 30 seconds;
    A.callcreate.value(4)(1,2,2,t1,t2,t3);
    B.callbid.value(2)();
    C.callbid.value(2)();

    uint[2] memory c1 = conn.createCommitment(r1,b1);
    uint[2] memory c2 = conn.createCommitment(r2,b2);

    B.callcoC.value(5)(c1,c2,2,3,t4,t5);
    assertEq(1, uint(co.stateC()));

    assertTrue(B.callColluderTimer());
    assertEq(3, uint(co.stateC()));

    uint[2] memory balance = co.getBalance();
    assertEq(5, balance[0]);
    assertEq(0, balance[1]);
  }

   /****************** TRAITORS CONTRACT TEST FUNCTIONS **********************/
   function testTraitorContract(){
     setEligible();

     uint[2] memory c1 = conn.createCommitment(r1,b1);
     uint[2] memory c2 = conn.createCommitment(r2,b2);
     (t,n) = conn.createEqualityProof(r1, r2, r3, c1, c2);

     A.callcreate.value(4)(1,2,2,T1,T2,T4);

     B.callbid.value(2)();
     C.callbid.value(2)();

     B.callcoC.value(5)(c1,c2,2,3,T4,T5);

     assertTrue(A.callcreateT.value(3)(address(B)));
     assertTrue(B.calljoinT.value(2)());

     B.calldeliverT(c1, t, n);
     assertEq(3, uint(tr.stateT()));

     B.calldeliver(c1, t, n);
     C.calldeliver(c2, t, n);

     A.callPay();

     uint[2] memory c4 = conn.createCommitment(r7,b4);
     uint[2] memory c3 = conn.createCommitment(r4,b3);

     // Create an equality proof
     (t3,n3) = conn.createEqualityProof(r7, r4, r1, c4, c3);

     // Create an equality proof
     uint[2] memory t1; uint[2] memory _t1;
     (t1,_t1,n1,_n1) = conn.createInequalityProof(b1, b3, r1, r4, r5, r6, c1, c3);

     uint[2] memory t2; uint[2] memory _t2;
     (t2,_t2,n2,_n2) = conn.createInequalityProof(b2, b3, r2, r4, r6, r7, c2, c3);

     assertEq(4, D.calldispute(c3,t1,_t1,t2,_t2,n1,_n1,n2,_n2));

     (t_3,_t_3,n_3,_n_3) = conn.createInequalityProof(b4, b3, r2, r4, r6, r7, c4, c3);

     assertEq(2, A.callcheck(c4, t3, n3, t_3, _t_3, n_3, _n_3));

   }

}
