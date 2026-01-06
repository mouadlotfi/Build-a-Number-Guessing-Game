#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0

# Prompt for username
echo "Enter your username:"
read USERNAME

# Check if user exists
USER_INFO=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_INFO ]]
then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  
  # Insert new user
  INSERT_USER=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
else
  # Existing user
  echo "$USER_INFO" | while IFS="|" read USER_ID GAMES_PLAYED BEST_GAME
  do
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
  
  USER_ID=$(echo "$USER_INFO" | cut -d'|' -f1)
fi

# Start guessing
echo "Guess the secret number between 1 and 1000:"

while true
do
  read GUESS
  
  # Check if input is an integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi
  
  # Increment guess count
  NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))
  
  # Check the guess
  if [[ $GUESS -eq $SECRET_NUMBER ]]
  then
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    
    # Update user stats
    USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE user_id=$USER_ID")
    GAMES_PLAYED=$(echo "$USER_INFO" | cut -d'|' -f1)
    BEST_GAME=$(echo "$USER_INFO" | cut -d'|' -f2)
    
    NEW_GAMES_PLAYED=$((GAMES_PLAYED + 1))
    
    if [[ -z $BEST_GAME || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]
    then
      NEW_BEST_GAME=$NUMBER_OF_GUESSES
    else
      NEW_BEST_GAME=$BEST_GAME
    fi
    
    UPDATE_USER=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED, best_game=$NEW_BEST_GAME WHERE user_id=$USER_ID")
    
    break
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done
