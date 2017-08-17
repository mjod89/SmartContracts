/* Traitor's contract
// this is the third contract and will be signed by the client and one of the cheated clouds.
// in this contract the cheated cloud will deliver a correct commitment, then the contract will cheack the state of Prisoner.
// base on the state the cloud either get back their fund of lose.
// for more info. go to the paper.
*/ Traotor's contract.

contract Traitors{
    address public client;
    address public traitor;

    LocalCrypto con;
    prisoners CTP;
    Colluders CTC;


    uint[2] public com;
    bool Correct = false;
    
    //A1: the address of the other cloud in CTP
    //A2: the other address of traitor in CTP
    address public A1;address public A2;



    enum StateT{INIT, Created, Joined, Computed, Done, Aborted}
    StateT public stateT = StateT.INIT;


    function Traitors(address pri, address Col, LocalCrypto _con) {
        con = _con;
        CTP = prisoners(pri);
        CTC = Colluders(Col);
        client=msg.sender;
    }

    //fallback function
    function() payable {
      throw;
    }

    // first function CREATE
    function create(address _traitor) payable returns (bool){
        uint T=now;
        assert(msg.sender == client);
        assert(stateT == StateT.INIT);
        assert(T<CTP.T2());
        assert(msg.value == (CTP.w() + 2*CTP.d() - CTP.ch()));
        
        
        traitor=_traitor;
        //change the state to created
        stateT = StateT.Created;
        
        return true;

    }// end of CREATE

    //second function JOIN
    function Join(address _A1,address _A2) payable returns (bool){
        uint T=now;
        assert(msg.sender==traitor);
        assert(msg.value==CTP.ch());
        assert(stateT == StateT.Created);
        assert(T<CTP.T2());
        assert(uint(CTP.state()) == 2);
        
        A1=_A1;
        A2=_A2;
        stateT = StateT.Joined;
        return true;
        

    }//end of JOIN

    //Third Function DELIVER
    //c1: new commitment from traitor
    function Deliver (uint[2] c1) returns (bool){
        uint T =now;
        assert(stateT == StateT.Joined);
        assert(uint(CTP.state()) == 2);
        assert(T<CTP.T2());
        
        
        //store the received result
        com[0] = c1[0];
        com[1] = c1[1];
        
        stateT = StateT.Computed; // change the state
        
        return true;


    }//end of DELIVER

    // Fourth Function CHECK
    //eq: boolean to say whether the equality or inequality NIZK is provided
    //if equality NIZK  then use (t1,n1)
    //if inqueality NIZK then use (t1,n1,t2,n2)

    function Check ( bool eq, uint[2]t1, uint[2]t2, uint n1, uint n2) returns (uint D1){
        
        assert(msg.sender == client);
        assert(stateT == StateT.Computed);
        assert(uint(CTP.state()) == 4);
        
        uint[2] memory c1;
	    c1[0] = com[0];	
	    c1[1] = com[1];
	    

        //result from TTP in CTP
        uint[2] memory ct1 = CTP.getTTPR();	
        
        // check the provided result with the CTP.TTP result
        if (eq){
          if(con.verifyEqualityProof(n1, c1 , ct1, t1)){
            Correct = true;
           }
           //shouldn't reach here
           else throw;
        }
        else {
          if(con.verifyInequalityProof(c1, ct1, t1, t2, n1, n2)){
            Correct = false;
          }
          //shouldn't reach here
          else throw;
        }
        
        bool[2] memory cheated;
   
        //whether the othe cloud cheated in CTP
        cheated[0]=CTP.getCheated(A1);
        //whether traitor cheated in CTP
        cheated[1]=CTP.getCheated(A2);
        
        uint w = CTP.w();
        uint d= CTP.d();
	    
	    bool succ;
        // none of clouds cheated in CTP
        if (cheated[0] == false && cheated[1] == false){

            succ=client.send(w+2*d);
            //for debugging
            if(!succ){
                return D1=12;
            }
            
            D1 = 1;
        }
        // if in CTP the other didn't cheat and traitor cheated and delivered correct answer
        else if(cheated[0] == false && cheated[1] == true && Correct == true){

            succ=client.send(2*d);
            //for debugging
            if(!succ){
                return D1=13;
            }
            
            succ=traitor.send(w);
                        //for debugging
            if(!succ){
                return D1=14;
            }

            D1 = 2;
        }
        
        // if in CTP both cheated and C2 delivered correct answer
        else if (cheated[0] == true && cheated[1] == true && Correct == true){

            succ=traitor.send(w+2*d);
            //for debugging
            if(!succ){
                return D1=15;
            }
            D1 = 3;
        }
        // else refund the deposit
        else {
            succ=traitor.send(CTP.ch());
            //for debugging
            if(!succ){
                return D1=16;
            }
            
            succ=client.send(this.balance);
            
            if(!succ){
                return D1=17;
            }
            
            D1 = 4;
        }

         stateT = StateT.Done;
         
         return D1;


    }//end CHECK


    // Fifth Function TIMER
    function Timer() returns (bool){
        uint T = now;
        
        //refund
        if (T >= CTP.T2() && stateT == StateT.Created){
            traitor.send(CTP.ch());
            client.send(this.balance);
            stateT = StateT.Aborted;
        }
        else if (T >= CTP.T2() && stateT == StateT.Computed){

            client.send(this.balance);
            stateT = StateT.Done;

        }
        if (T < CTP.T3() && stateT == StateT.Computed){
            traitor.send(this.balance);
            stateT = StateT.Done;
        }
    }//end TIMER

    function reset (){
      assert(msg.sender == client);
      assert(stateT == StateT.Done ||stateT == StateT.Aborted);
      stateT = StateT.INIT;

      if (!msg.sender.send(address(this).balance)){throw;}
    }

} // end of the Traidors contract
