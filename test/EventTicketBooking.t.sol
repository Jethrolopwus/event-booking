 // SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/EventTicketBooking.sol";

contract EventTicketBookingTest is Test {
    EventTicketBooking public booking;
    address public owner = address(this);
    address public user = address(1);
    uint public ticketPrice = 0.1 ether;
    uint public maxTickets = 100;

    function setUp() public {
        booking = new EventTicketBooking(ticketPrice, maxTickets);
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

        uint balanceBefore = owner.balance;
        booking.withdrawFunds();
        uint balanceAfter = owner.balance;

        assertEq(balanceAfter - balanceBefore, ticketPrice * quantity);
    }
}
