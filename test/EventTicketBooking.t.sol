 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/EventTicketBooking.sol";

contract PayableUser {
    receive() external payable {}
}

contract EventTicketBookingTest is Test {
    EventTicketBooking public booking;
    address public owner = address(this);
    address public user;
    PayableUser public userC;
    uint public ticketPrice = 0.1 ether;
    uint public maxTickets = 10;

    receive() external payable {}

    function setUp() public {
        booking = new EventTicketBooking(ticketPrice, maxTickets);
        userC = new PayableUser();
        user = address(userC);
        vm.deal(user, 10 ether);
    }

    function testInitialValues() public view {
        assertEq(booking.ticketPrice(), ticketPrice);
        assertEq(booking.maxTickets(), maxTickets);
        assertEq(booking.ticketsSold(), 0);
    }

    function testBuyTickets() public {
        uint quantity = 2;
        uint eventDateTime = block.timestamp + 1 days;

        vm.prank(user);
        booking.buyTickets{value: ticketPrice * quantity}(eventDateTime, quantity);

        assertEq(booking.ticketsSold(), quantity);
    }

    function testBuyTicketsIncorrectPayment() public {
        uint quantity = 2;
        uint eventDateTime = block.timestamp + 1 days;

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(EventTicketBooking.IncorrectPayment.selector, ticketPrice * quantity, ticketPrice)
        );
        booking.buyTickets{value: ticketPrice}(eventDateTime, quantity);
    }

    function testRefundTicket() public {
        uint eventDateTime = block.timestamp + 1 days;

        vm.prank(user);
        booking.buyTickets{value: ticketPrice}(eventDateTime, 1);

        uint ticketId = 1;

        vm.prank(user);
        booking.refundTicket(ticketId);

        assertEq(booking.ticketsSold(), 0);
    }

    function testTicketsSoldOut() public {
        uint eventDateTime = block.timestamp + 1 days;

        for (uint i = 0; i < maxTickets; i++) {
            vm.prank(user);
            booking.buyTickets{value: ticketPrice}(eventDateTime, 1);
        }

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(EventTicketBooking.TicketsSoldOut.selector, maxTickets));
        booking.buyTickets{value: ticketPrice}(eventDateTime, 1);
    }

    function testWithdrawFunds() public {
    uint quantity = 5;
    uint eventDateTime = block.timestamp + 1 days;

    vm.prank(user);
    booking.buyTickets{value: ticketPrice * quantity}(eventDateTime, quantity);

    uint contractBalance = address(booking).balance;
    assertEq(contractBalance, ticketPrice * quantity);


    uint balanceBefore = owner.balance;
    console.log(balanceBefore);

    vm.prank(owner); 
    booking.withdrawFunds();

   
    uint balanceAfter = owner.balance;
    assertEq(balanceAfter - balanceBefore, ticketPrice * quantity);
}

}
