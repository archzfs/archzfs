#!/bin/bash


test_setup_exit() {
    msg "Installation complete!"
    systemctl reboot
}


test_met_acceptance_criteria() {
    return 1
}
