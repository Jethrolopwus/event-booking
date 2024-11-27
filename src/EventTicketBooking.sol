// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventTicketBooking {
    struct Ticket {
        uint id;
        address buyer;
        uint eventDateTime;
    }

    address public owner;
    uint public ticketPrice;
    uint public maxTickets;
    uint public ticketsSold;

    mapping(uint => Ticket) public tickets;

    error NotOwner();
    error IncorrectPayment(uint expected, uint received);
    error TicketsSoldOut(uint maxTickets);
    error NotTicketOwner(uint ticketId);
    error InsufficientContractBalance();
    error DirectPaymentsNotAllowed();

    event TicketPurchased(address indexed buyer, uint ticketId, uint eventDateTime);
    event TicketRefunded(address indexed buyer, uint ticketId);
    event EventUpdated(uint ticketPrice, uint maxTickets);

    bool private locked;

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier validPayment(uint quantity) {
        uint expectedPayment = ticketPrice * quantity;
        if (msg.value != expectedPayment) revert IncorrectPayment(expectedPayment, msg.value);
        _;
    }

    constructor(uint _ticketPrice, uint _maxTickets) {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
        maxTickets = _maxTickets;
        ticketsSold = 0;
    }

    function buyTickets(uint _eventDateTime, uint quantity)
        external
        payable
        nonReentrant
        validPayment(quantity)
    {
        if (ticketsSold + quantity > maxTickets) revert TicketsSoldOut(maxTickets);

        for (uint i = 0; i < quantity; i++) {
            ticketsSold++;
            tickets[ticketsSold] = Ticket(ticketsSold, msg.sender, _eventDateTime);
            emit TicketPurchased(msg.sender, ticketsSold, _eventDateTime);
        }
    }

    function refundTicket(uint _ticketId) external nonReentrant {
        Ticket storage ticket = tickets[_ticketId];
        if (ticket.buyer != msg.sender) revert NotTicketOwner(_ticketId);

        delete tickets[_ticketId];
        ticketsSold--;

        payable(msg.sender).transfer(ticketPrice);

        emit TicketRefunded(msg.sender, _ticketId);
    }

    function updateEventDetails(uint _newTicketPrice, uint _newMaxTickets) external onlyOwner {
        ticketPrice = _newTicketPrice;
        maxTickets = _newMaxTickets;

        emit EventUpdated(_newTicketPrice, _newMaxTickets);
    }

    function withdrawFunds() external onlyOwner nonReentrant {
        if (address(this).balance == 0) revert InsufficientContractBalance();

        payable(owner).transfer(address(this).balance);
    }

    function getAvailableTickets() external view returns (uint) {
        return maxTickets - ticketsSold;
    }

    receive() external payable {
        revert DirectPaymentsNotAllowed();
    }
}
