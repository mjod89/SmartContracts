/*colluder's contract
// this contract will be signed by the colluder cloud and they will agree on a commitment to be delived to Prisoner contract. 
// they will deposit an amount of Ether if the there is not collusion on Prisoner the deposit will be refunded to them,
// otherwise, the cheating in this contract will lose their deposit.
// for more info. go to the paper. 
*/ Colluder contract.

contract Colluders {

    enum StateC {INIT, Created, Colluded, Aborted, Done}
    StateC public stateC = StateC.INIT;


    uint[2] public commitment1;
    uint[2] public commitment2;

    prisoners C; // class instance to call variables e.g. T and state
    uint t=0;
    uint b=0;

    //uint public T ;
    uint public T4 ;
    uint public T5;
    
    address public ringLeader;
    address public follower;

    // constructer to get the address of Prisoners and parties' addresses
    function Colluders(address Prio,address _follower) {
        C = prisoners(Prio);
        ringLeader=msg.sender;
        follower=_follower;
        
    }

    //fallback function
    function() payable {
      throw;
    }

    //First Function Create(). Ringleader pays t+b into the contract
    //R1: commitment
    //R2: commitment
    //_t,_b: amount of deposit and bribe
    //_T4,_T5: deadlines
    function Create(uint[2] R1, uint[2] R2, uint _t, uint _b, uint _T4, uint _T5) payable returns(bool){
       uint T=now;
       
        //sanity checks
       assert(msg.sender == ringLeader);
       assert(T < _T4 && _T4 < C.T2() && C.T2() < C.T3() && C.T3() < _T5);
       assert(stateC == StateC.INIT);
       assert(C.getState() == 2 );
       assert(msg.value == t + b );
       
       //initialize parameters
       T4 = _T4; T5 = _T5;t=_t;b=_b;
       commitment1[0] = R1[0];
       commitment1[1] = R1[1];
       commitment2[0] = R2[0];
       commitment2[1] = R2[1];
       
       //change the state to Created
       stateC = StateC.Created ;
       
       //for debugging
       return true;

    } // end of CREATE

    // Second Function JOIN(). follower pays t into the contract
    function Join () payable returns (bool ) {
        uint T = now;
        
        assert(stateC == StateC.Created);
        assert(T<T4);
        assert(C.getState() == 2 );
        assert(msg.sender==follower);
        assert(msg.value == t);
        

        //update the state
        stateC = StateC.Colluded;
        
        //for debugging
        return true;
    } //end of JOIN()

    // Third Function Enforce()
    // A1: address of ringleader in CTP, which may be different from the currently used address
    // A2: address of follower in CTP, which may be different from the currently used address
    function Enforce(address A1,address A2) returns (bool){
        uint T = now;
        
        assert(T>=T5 && stateC == StateC.Colluded && C.getState() == 4);
        
        
        // CTP results of ringleader = 'test1' and follower = "test2"
        uint[2] memory test1;
        uint[2] memory test2;
        (test1, test2) = C.getCom(A1,A2);
        
        bool succ;
        
        //no one deviated from collusion
        if ((test1[0] == commitment1[0] && test1[1] == commitment1[1]) && (test2[0] == commitment2[0] && test2[1] == commitment2[1])){
                succ = ringLeader.send(t);
                assert(succ);
                
                succ = follower.send(t+b);
                assert(succ);

            }
        //ringLeader deviated
        else if ((test1[0] != commitment1[0] || test1[1] != commitment1[1]) && (test2[0] == commitment2[0] && test2[1] == commitment2[1])){
                succ = follower.send(2*t+b);
                assert(succ);
 
            }
        //follower deviated    
        else if ((test1[0] == commitment1[0] && test1[1] == commitment1[1]) && (test2[0] != commitment2[0] || test2[1] != commitment2[1])){
                succ = ringLeader.send(2*t+b);
                assert(succ);

            }
        // both deviated
        else {

                succ = ringLeader.send(t+b);
                assert(succ);
                
                succ = follower.send(t);
                assert(succ);

        }
        
        //update state
        stateC=StateC.Done;
        
        //for debugging
        return true;

    } // end of Enforce()

    function Timer() returns (bool){
        uint T = now;
        
        assert(T>=T4 && stateC == StateC.Created);
        
        bool succ;
        
        succ = ringLeader.send(t+b);
        assert(succ);
                
        succ = follower.send(t);
        assert(succ);

        stateC = StateC.Aborted;
        
        return true;
        
        
    }// end of Timer()

    function reset(){
        assert(msg.sender == ringLeader);
        assert(stateC==StateC.Done||stateC==StateC.Aborted);
        
        stateC = StateC.INIT;
        T4 =0; T5 =0; t = 0; b = 0;
        
        if (!msg.sender.send(address(this).balance)){throw;}

}

} // end of Colluder Contracts
