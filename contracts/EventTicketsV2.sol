pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;

    uint   PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint[] private eventIds;
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
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

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping(uint => Event) events;

    // Events to emit
    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier checkOwner(address isThisTheOwner) {
      require(isThisTheOwner == owner, 'This is not the owner!');
       _;}

    // Modifier to check if event is open
    modifier isEventOpen(uint id) {
      require(events[id].isOpen == true, 'Event is closed!');
       _;}

    // Modifier to check payment
    modifier enoughPayment(uint tickets) {
      require(msg.value <= (tickets * PRICE_TICKET), "Not enough payment!");
       _;}

    // Modifier to check if enough tickets are available
    modifier enoughTicketsAvailable(uint tickets, uint eventId) {
      require(tickets <= events[eventId].totalTickets, "Not enough tickets available!");
      _;}

    modifier isPurchaser(uint id) {
      require(getBuyerNumberTickets(id) > 0, "This address has yet to purchase any tickets");
    _;}


  constructor () public
    {
      owner = msg.sender;
    }


    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory description, string memory url, uint tickets)
    public
    checkOwner(msg.sender)
    returns (uint id)
    {
      id = idGenerator;
      events[id] = Event(description, url, tickets, 0, true);
      idGenerator++;
      eventIds.push(id);
      emit LogEventAdded(description, url, tickets, id);
      return (id);
    }


    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint id)
    public view
    returns (string memory description, string memory url, uint ticketsAvailable, uint sales, bool isOpen)
    {
      Event memory atId = events[id];
      return (atId.description, atId.url, (atId.totalTickets - atId.sales), atId.sales, atId.isOpen);
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint Id, uint tickets)
    public payable
    isEventOpen(Id)
    enoughPayment(tickets)
    enoughTicketsAvailable(tickets, Id)
    {
      events[Id].buyers[msg.sender] += tickets;
      events[Id].totalTickets -= tickets;
      events[Id].sales += tickets;
      msg.sender.transfer(msg.value - PRICE_TICKET * tickets);
      emit LogBuyTickets(msg.sender, Id, tickets);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint id)
    public payable
    isPurchaser(id)
    {
      uint tickets = events[id].buyers[msg.sender];
      events[id].buyers[msg.sender] -= tickets;
      events[id].totalTickets += tickets;
      events[id].sales -= tickets;
      msg.sender.transfer(PRICE_TICKET * tickets);
      emit LogGetRefund(msg.sender, id, tickets);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */

    function getBuyerNumberTickets(uint id)
    public view
    returns(uint ticketCount)
    {
      return(events[id].buyers[msg.sender]);
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint id)
    public payable
    checkOwner(msg.sender)
    {
      events[id].isOpen = false;
      emit LogEndSale(owner, address(this).balance, id);
      msg.sender.transfer(address(this).balance);
    }
}
