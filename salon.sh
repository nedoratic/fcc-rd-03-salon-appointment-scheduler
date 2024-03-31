#!/bin/bash

PSQL="psql -U postgres -d salon -tAc"

# Function for main menu
MAIN_MENU() {
    if [[ $1 ]]; then
        echo -e "\n$1"
    fi

    echo -e "~~~~~ MY SALON ~~~~~\n"
    echo "Welcome to My Salon, how can I help you?"
    echo -e "\nServices offered:"
    local count=1
    $PSQL "SELECT name FROM services;" | while read -r name; do
        echo "$count) $name"
        ((count++))
    done

    echo -e "\nPlease enter the service ID: "
    read SERVICE_ID_SELECTED

    # Validate service ID
    case $SERVICE_ID_SELECTED in
        1|2|3)
            VALIDATE_SERVICE_ID "$SERVICE_ID_SELECTED"
            ;;
        *)
            MAIN_MENU "I could not find that service. What would you like today?"
            ;;
    esac
}

# Function to validate service ID
VALIDATE_SERVICE_ID() {
    local service_id=$1
    local service_count=$($PSQL "SELECT COUNT(*) FROM services WHERE service_id = $service_id;")
    if [ "$service_count" -eq 0 ]; then
        MAIN_MENU "I could not find that service. What would you like today?"
    else
        PROMPT_CUSTOMER_INFO "$service_id"
    fi
}

# Function to prompt for customer information
PROMPT_CUSTOMER_INFO() {
    local service_id=$1
    echo -e "\nWhat's your phone number?"
    read CUSTOMER_PHONE

    # Check if the phone number exists in the customers table
    local customer_count=$($PSQL "SELECT COUNT(*) FROM customers WHERE phone = '$CUSTOMER_PHONE';")

    if [ "$customer_count" -eq 0 ]; then
        echo -e "\nI don't have a record for that phone number, what's your name?"
        read CUSTOMER_NAME
        INSERT_NEW_CUSTOMER "$CUSTOMER_PHONE" "$CUSTOMER_NAME" "$service_id"
    else
        PROMPT_APPOINTMENT_TIME "$service_id"
    fi
}

# Function to insert new customer
INSERT_NEW_CUSTOMER() {
    local phone=$1
    local name=$2
    local service_id=$3
    $PSQL "INSERT INTO customers (phone, name) VALUES ('$phone', '$name');"
    PROMPT_APPOINTMENT_TIME "$service_id"
}

# Function to prompt for appointment time
PROMPT_APPOINTMENT_TIME() {
    local service_id=$1
    echo -e "\nWhat time would you like your appointment?"
    read SERVICE_TIME
    ADD_APPOINTMENT "$service_id" "$CUSTOMER_PHONE" "$SERVICE_TIME" "$CUSTOMER_NAME"
}

# Function to add an appointment
ADD_APPOINTMENT() {
    local service_id=$1
    local phone=$2
    local time=$3
    local name=$4

    $PSQL "INSERT INTO appointments (service_id, customer_id, time) 
           SELECT $service_id, customer_id, '$time' 
           FROM customers WHERE phone = '$phone';"

    echo -e "\nI have put you down for a $(GET_SERVICE_NAME $service_id) at $time, $name."
}

# Function to get service name
GET_SERVICE_NAME() {
    local service_id=$1
    $PSQL "SELECT name FROM services WHERE service_id = $service_id;"
}

# Call the main menu function
MAIN_MENU
