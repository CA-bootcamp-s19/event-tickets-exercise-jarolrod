pragma solidity ^0.5.0;

    /*
        The EventTickets contract keeps track of the details and ticket sales of one event.
     */

contract EventTickets {

    /*
        Create a public state variable called owner.
        Use the appropriate keyword to create an associated getter function.
        Use the appropriate keyword to allow ether transfers.
     */
    address public owner;

    uint TICKET_PRICE = 100 wei;

    /*
        Create a struct called "Event".
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */

    struct Event {
      string description;
      string url;
      uint totalTickets;
      uint sales;
      mapping (address => uint) buyers;
      bool isOpen;
    }

    Event myEvent;

    /*
        Define 3 logging events.
        LogBuyTickets should provide information about the purchaser and the number of tickets purchased.
        LogGetRefund should provide information about the refund requester and the number of tickets refunded.
        LogEndSale should provide infromation about the contract owner and the balance transferred to them.
    */
    event LogBuyTickets(address buyer, uint ticketsPurchased);
    event LogGetRefund(address refundRequest, uint ticketsPurchased);
    event LogEndSale(address owner, uint transferValue);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier checkOwner(address isThisTheOwner) {
      require(isThisTheOwner == owner, "This is not the owner!");
    _;}

    // Check that event is currently open
    modifier isEventOpen() {
      require(myEvent.isOpen == true, "The event is not open");
    _;}

    // Check that enough payment has been recieved
    modifier enoughPayment(uint tickets) {
      require(msg.value >= (tickets * TICKET_PRICE), "Not enough payment recieved");
    _;}

    // Check that enough tickets are available
    modifier enoughTicketsAvailable(uint tickets) {
      require(tickets <= (myEvent.totalTickets), "Not Enough Tickets!");
    _;}


    // Check if buyer has purchased tickets
    modifier isPurchaser(address buyer) {
      require(getBuyerTicketCount(buyer) > 0, "This address has yet to purchase any tickets");
    _;}

    /*
        Define a constructor.
        The constructor takes 3 arguments, the description, the URL and the number of tickets for sale.
        Set the owner to the creator of the contract.
        Set the appropriate myEvent details.
    */
    constructor (string memory description, string memory url, uint tickets) public
    {
      owner = msg.sender;
      myEvent.description = description;
      myEvent.url = url;
      myEvent.totalTickets = tickets;
      myEvent.isOpen = true;
      myEvent.sales = 0;
    }

    /*
        Define a function called readEvent() that returns the event details.
        This function does not modify state, add the appropriate keyword.
        The returned details should be called description, website, uint totalTickets, uint sales, bool isOpen in that order.
    */
    function readEvent()
    public view
    returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen)
    {
      return (myEvent.description, myEvent.url, myEvent.totalTickets, myEvent.sales, myEvent.isOpen);
    }

    /*
        Define a function called getBuyerTicketCount().
        This function takes 1 argument, an address and
        returns the number of tickets that address has purchased.
    */

    function getBuyerTicketCount(address buyer)
    public view
    returns(uint ticketCount)
    {
      return(myEvent.buyers[buyer]);
    }

    /*
        Define a function called buyTickets().
        This function allows someone to purchase tickets for the event.
        This function takes one argument, the number of tickets to be purchased.
        This function can accept Ether.
        Be sure to check:
            - That the event isOpen
            - That the transaction value is sufficient for the number of tickets purchased
            - That there are enough tickets in stock
        Then:
            - add the appropriate number of tickets to the purchasers count
            - account for the purchase in the remaining number of available tickets
            - refund any surplus value sent with the transaction
            - emit the appropriate event
    */

    function buyTickets(uint tickets)
    public payable
    isEventOpen()
    enoughPayment(tickets)
    enoughTicketsAvailable(tickets)
    {
      myEvent.buyers[msg.sender] += tickets;
      myEvent.totalTickets -= tickets;
      myEvent.sales += tickets;
      msg.sender.transfer(msg.value - TICKET_PRICE * tickets);
      emit LogBuyTickets(msg.sender, tickets);
    }

    /*
        Define a function called getRefund().
        This function allows someone to get a refund for tickets for the account they purchased from.
        TODO:
            - Check that the requester has purchased tickets.
            - Make sure the refunded tickets go back into the pool of avialable tickets.
            - Transfer the appropriate amount to the refund requester.
            - Emit the appropriate event.
    */

    function getRefund()
    public payable
    isPurchaser(msg.sender)
    {
      uint tickets = myEvent.buyers[msg.sender];
      myEvent.totalTickets += tickets;
      myEvent.buyers[msg.sender] -= tickets;
      msg.sender.transfer(TICKET_PRICE * tickets);
      emit LogBuyTickets(msg.sender, tickets);
    }

    /*
        Define a function called endSale().
        This function will close the ticket sales.
        This function can only be called by the contract owner.
        TODO:
            - close the event
            - transfer the contract balance to the owner
            - emit the appropriate event
    */

    function endSale()
    public
    checkOwner(msg.sender)
    {
      myEvent.isOpen = false;
      emit LogEndSale(owner, address(this).balance);
      msg.sender.transfer(address(this).balance);
    }
}
