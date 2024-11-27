// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/EventTicketBooking.sol";

contract DeployEventTicketBooking is Script {
    function run() external {
        uint ticketPrice = 0.1 ether; 
        uint maxTickets = 100;       

        vm.startBroadcast();       
        EventTicketBooking eventTicketBooking = new EventTicketBooking(ticketPrice, maxTickets);
        vm.stopBroadcast();     

        console.log("EventTicketBooking deployed to:", address(eventTicketBooking));
    }
}
