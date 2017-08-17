/*prisoner's contract 
//this is the first contract and it should be signed by the clinet and the first and the second cloud.
//If there is a collusion the client can inform the third part to participate and solve the collusion.
// for more info. go to the paper.
*/

contract prisoners {
    //cryptography library
    LocalCrypto con;


    //addresses of parties
    address public client;
    address public C1;
    address public C2;
    address public TTP;

    mapping (address => uint ) public results;
    mapping (address => bool ) public hasBid;
    mapping (address => bool ) public hasDeliver;
    mapping (address => bool ) public Cheated;

    //commitments of function/output
    uint[2] public com_f;
    uint[2] public com_x;
    
    //commitments of result
    uint[2] public com1;
    uint[2] public com2;
    //TTP's commitment
    uint[2] public TTPR;

    //deadlines
    uint public T1;
    uint public T2;
    uint public T3;

    //amount of wage
    uint public w ;
    //TTP cost
    uint public ch;
    //amount deposit
    uint public d ;

   //all the states
    enum State {INIT, Created, Compute, Pay, Done, Error, Aborted,SendError}
    
    //current state
    State public state = State.INIT;

    //constructor
    function prisoners(LocalCrypto _con) {
        con = _con;
        client = msg.sender;
    }


    //fallback function
    function() payable {
      throw;
    }
    
    //Create function
    //The client needs to nominate workers and TTP
    function Create (uint[2] _com_f, uint[2] _com_x, uint _w, uint _d, uint _ch, uint _T1, uint _T2, uint _T3, address[2] addr, address _TTP) payable returns(bool){
          assert(msg.sender == client);
          
          //initiate contract parameters
          w = _w ; ch = _ch; d = _d; com_f= _com_f; com_x=_com_x;
          C1 = addr[0];
          C2 = addr[1];
          TTP=_TTP;
          //time 
    	  T1 = _T1 ;
          T2 = _T2;
          T3 = _T3;
          
          //current time
          uint T = now;
          
          //sanity checks
          assert(state == State.INIT );
          assert(T<T1 && T1<T2 && T2<T3);
          //must pay this amount into the contract
          assert(msg.value==((2 * w) + ch));

          //change the state
          state = State.Created;
          
          //for debugging
          return true;
    }

    //Second Function BID(); 
    function Bid() payable returns (bool sta){
        //current time
        uint T = now; 
        
        //sanity checks
        assert(state == State.Created);
        assert(T < T1);
        assert(msg.value == d);
        assert(!hasBid[msg.sender]);
        assert(msg.sender == C1 || msg.sender == C2);

        hasBid[msg.sender] = true;
        
        //change state if both have bid
        if (hasBid[C1]== true && hasBid[C2]== true ){ 
            state = State.Compute;
            
        }

        //for debugging
        return true;
    }// end BID

    //third function DELIVER; takes one input (the commitment of result); run by the clouds only.
    function Deliver (uint[2] com_y_i) returns (bool D){
        //current time
        uint T = now; 
        
        //sanity checks
        assert(msg.sender == C1 || msg.sender == C2);
        assert(state == State.Compute);
        assert(T < T2);
        assert(!hasDeliver[msg.sender]);
        
        //record the result
        if (msg.sender == C1){
            com1[0] = com_y_i[0];
            com1[1] = com_y_i[1];
        }
        else {
            com2[0] = com_y_i[0];
            com2[1] = com_y_i[1];
        }
        hasDeliver[msg.sender] = true;

        // if both clouds delivered results then change the state;
        if (hasDeliver[C1] == true && hasDeliver[C2] == true) {
                state = State.Pay;
        }
        
        //for debugging
        return true;
    } // end DELIVER

    // Fourth Function PAY; takse NIZK that is (t, n)
    function Pay (uint[2] t, uint n) returns (bool Do){
        //current time
        uint T = now;

        //sanity checks
        assert(state == State.Pay);
        assert(T < T3);
        
        
        bool succ;
        
        //if no one delivered
        if (hasDeliver[C1] == false && hasDeliver[C2]==false){
            //transfer the balance in the contract to the client
           succ = client.send(this.balance);
           assert(succ);
           //change the state
           state = State.Done;
        }
        //if both delivered
        else if (hasDeliver[C1] == true && hasDeliver[C2]==true){
            //if both results are equal
            if((con.verifyEqualityProof(n, com1, com2,t))){
                //pay C1 and refund deposit
                succ = C1.send(w+d);
                assert(succ);
                
                //pay C2 and refund deposit
                succ = C2.send(w+d);
                assert(succ);
                
                //refund the client 
                succ = client.send(ch);
                assert(succ);
                //change the state
                state = State.Done;
                Do  = true;
            }
            //shouldn't reach here
            else {
                Do = false;
                state = State.Error;
            }

        }
        //shouldn't reach here
        else {
            Do = false;
            state = State.Error;
        }
        
        //for debugging
        return Do;
    }// end of PAY

    // Fifth Function DISPUTE, takes one input and returns bool
    // commitment from TTP: c3
    // inequality NIZK for C1:(t1,n1,_t1,_n1);
    // inequality NIZK for C2:(t2,n2,_t2,_n2);
    function Dispute(uint[2] c3, uint[2] t1, uint[2] _t1, uint n1, uint _n1, uint[2] t2, uint[2] _t2, uint n2, uint _n2) returns (uint Done){
        // check the sender must be TTP else quit
        assert(msg.sender == TTP);
        
        //dispute resolution start
        
        TTPR[0] = c3[0];
        TTPR[1] = c3[1];
        

        // check C1's result
        if (hasDeliver[C1] == true && con.verifyInequalityProof(com1, TTPR, t1, _t1, n1, _n1)){
            Cheated[C1] = true;
        }
        else {
         Cheated[C1] = false;
        }

       // check the C2's result
       if (hasDeliver[C1] == true && con.verifyInequalityProof(com2, TTPR, t2, _t2, n2, _n2)){
            Cheated[C2] = true;
        } else {
          Cheated[C2] = false;
        }
        
        bool succ;
        
       //both cheated
       if (Cheated[C1] == true && Cheated[C2] == true){

         //punish both clouds
         succ= client.send(2*(w+d));
         
         //for debugging
         if(!succ){
            return Done = 1112;
         }else{
            Done = 1;
         }
       }       
       // no one cheated
       else if(Cheated[C1] == false && Cheated[C2] == false){
           

         //pay C1
         succ= C1.send(w+d);
         //for debugging
         if(!succ){
            return Done = 1113;
         }
         
         //pay C2
         succ= C2.send(w+d);
         //for debugging
         if(!succ){
            return Done = 1114;
         }

          Done = 2;
      }
      // C1 Cheated
      else if (Cheated[C1] == true && Cheated[C2] == false){
         //pay C2
         succ= C2.send(w+2*d-ch);
         //for debugging
         if(!succ){
            return Done = 1115;
         }
        //pay the client
         succ= client.send(w+ch);
         //for debugging
         if(!succ){
            return Done = 1116;
         }

        Done = 3;
        }

      //C2 cheated
      else if (Cheated[C1] == false && Cheated[C2] == true){
         //pay C1
         succ= C1.send(w+2*d-ch);
         //for debugging
         if(!succ){
            return Done = 1117;
         }
        //pay the client
         succ= client.send(w+ch);
         //for debugging
         if(!succ){
            return Done = 1118;
         }

          Done = 4;
      }

        //pay the TTP
        succ = TTP.send(ch);
        
        //for debugging
        if(!succ){
            return Done = 1111;
        }
        Done = 5;
        
        state = State.Done;
        return Done;
        
    }//end DISPUTE


    //Seventh Function TIMER
    function Timer() returns (bool Time){
        uint T = now;
        bool succ;
        
        if ((T>=T1) && state == State.Created){
           //refund the client
           succ= client.send(2*w+ch);
           assert(succ);
           
           //refund other party who has paid
           if (hasBid[C1]==true){
               succ= C1.send(d);
               assert(succ);
               
           }
           if (hasBid[C2]==true){
               succ= C2.send(d);
               assert(succ);
           }
            state = State.Aborted;
            
        }else if ((T>=T2) && state == State.Compute){
            //move to pay state
            state = State.Pay;
        }else if ((T>=T3) && state == State.Pay){
            //pay who has delivered a result
            if(hasDeliver[C1] == true){
               succ= C1.send(w+d);
               assert(succ);
            }
            if(hasDeliver[C2] == true){
               succ= C2.send(w+d);
               assert(succ);
            }
            //rest goes to the client
           succ= client.send(this.balance);
           assert(succ);
           state = State.Done;
           
        }

    }

    function reset() returns (bool){
      assert(msg.sender == client);
      assert(state == State.Done||state==State.Aborted);
      
      delete results[C1];
      delete results[C2];
      
      delete hasBid[C1];
      delete hasBid[C2];
      delete Cheated[C1];
      delete Cheated[C2];
      delete hasDeliver[C1];
      delete hasDeliver[C2];

      C1=0;
      C2=0;
      TTP=0;
      
      w = 0; ch = 0; d = 0; T1 =0; T2 = 0; T3 = 0;

      state = State.INIT;

      if (!client.send(address(this).balance)){return false;}
    }


    //return the commitment of TTP
    function getTTPR() returns (uint[2] memory TTPr){
        TTPr = TTPR;
    }

    //return the state of this contract to be used by the others
    function getState() returns(uint x){
       x = uint(state);
    }

    //this function is used by colluder and traitor contract to check who cheat
    function getCheated(address a) returns (bool){
        return Cheated[a];
    }

    //this function return commitments of both clouds to be used by colluders contract.
    //A1 and A2 are addresses
    function getCom(address A1, address A2) returns (uint[2] memory _com1, uint[2] memory _com2){
        
        if(A1==C1 && A2==C2){
            _com1 = com1;
            _com2 = com2;
        }else if(A2==C1 && A1 == C2){
            _com2 = com1;
            _com1 = com2;
        }
        else throw;
    }

} // end prisoners contract
