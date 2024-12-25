use `FAA`;

/*
Problem 1
Problem Formulation
1. Data Attributes in the result set:
	Airline Name, Maximum Departure Delay in minutes
2. Data Attributes used in the condition:
	Departure Delay
3. Tables with relevant information:
	al_perf, L_AIRLINE_ID
4. Useful attributes in the tables:
	DepDelayMinutes, airline name
5. Joining the tables:
	al_perf.Reporting_Airline = substring_index(L_AIRLINE_ID.Name, ': ', -1)
6. Conditions to be satisfied:
	maximum departure delay for each airline
*/
select
    substring_index(L_AIRLINE_ID.Name, ':', 1) as Airline_Name,
    max(al_perf.DepDelayMinutes) as Max_Delay
from al_perf
join L_AIRLINE_ID
on al_perf.Reporting_Airline = substring_index(L_AIRLINE_ID.Name, ': ', -1)
group by Airline_Name
order by Max_Delay asc;
# number of rows returned: 16

/*
Problem 2
Problem Formulation
1. Data Attributes in the result set:
	Airline Name, Maximum Early Departure in minutes
2. Data Attributes used in the condition:
	-(Departure Delay)
3. Tables with relevant information:
	al_perf, L_AIRLINE_ID
4. Useful attributes in the tables:
	DepDelay, airline name
5. Joining the tables:
	al_perf.Reporting_Airline = substring_index(L_AIRLINE_ID.Name, ': ', -1)
6. Conditions to be satisfied:
	maximum early departure for each airline = 
    maximum of -(departure delay) for each airline
*/
select
    substring_index(L_AIRLINE_ID.Name, ':', 1) as Airline_Name,
    max(-al_perf.DepDelay) as Max_Early_Departure
from al_perf
join L_AIRLINE_ID
on al_perf.Reporting_Airline = substring_index(L_AIRLINE_ID.Name, ': ', -1)
where al_perf.DepDelay < 0
group by Airline_Name
order by Max_Early_Departure desc;
# number of rows returned: 16

/*
Problem 3
Problem Formulation
1. Data Attributes in the result set:
	Day of the week,  number of flights, rank
2. Tables with relevant information:
	al_perf, L_WEEDAYS
3. Useful attributes in the tables:
	DayOfWeek, Code, Day
4. Joining the tables:
	al_perf join L_WEEKDAYS on al_perf.DayOfWeek = L_WEEKDAYS.Code
*/
select 
	rank() over (order by count(al_perf.DayOfWeek) desc) as rank_of_day,
	L_WEEKDAYS.Day as Day_Name,
	count(al_perf.DayOfWeek) AS Number_of_flights
from al_perf 
join L_WEEKDAYS 
on al_perf.DayOfWeek = L_WEEKDAYS.Code
group by L_WEEKDAYS.Day
order by Number_of_flights desc;
# number of rows returned: 7

/*
Problem 4
Problem Formulation
1. Data Attributes in the result set:
	Airport Name, Airport Code, Average Departure Delays
2. Data Attributes used in the condition:
	Average Departure Delay
3. Tables with relevant information:
	al_perf, L_AIRPORT_ID
4. Useful attributes in the tables:
	DepDelayMinutes, airport name, airport id
5. Joining the tables:
	al_perf join L_AIRPORT_ID on al_perf.originAirportID = L_AIRPORT_ID.ID
6. Conditions to be satisfied:
	maximum average departure delay out of all airports
*/
select 
	substring_index(L_AIRPORT_ID.Name, ':', -1) as Airport_Name,
    L_AIRPORT_ID.ID as Airport_Code,
    round(avg(al_perf.DepDelayMinutes), 4) as Avg_dep_Delay
from al_perf
join L_AIRPORT_ID 
on al_perf.originAirportID = L_AIRPORT_ID.ID
group by L_AIRPORT_ID.ID, Airport_Name
order by Avg_dep_Delay desc
limit 1;
# number of rows retuned: 1


/*
Problem 5
Problem Formulation
1. Data Attributes in the result set:
	airline name, airport name, average delay 
2. Data Attributes used in the condition:
	average departure delay
3. Tables with relevant information:
	al_perf, L_AIRLINE_ID, L_AIRPORT_ID
4. Useful attributes in the tables:
	Reporting_Airline, originAirportID, DepDelayMinutes, L_AIRLINE_ID.Name, L_AIRPORT_ID.Name
5. Joining the tables:
	AirlineAirportAvgDelays.Reporting_Airline = substring_index(L_AIRLINE_ID.Name, ': ', -1)
	AirlineAirportAvgDelays.originAirportID = L_AIRPORT_ID.ID
6. Conditions to be satisfied:
	maximum average departure delay out for all airports for each airline
*/
with AirlineAirportAvgDelays as (
    select 
        al_perf.Reporting_Airline,
        al_perf.originAirportID,
        avg(al_perf.DepDelayMinutes) as Avg_Departure_Delay
    from 
        al_perf
    group by 
        al_perf.Reporting_Airline, al_perf.originAirportID
),
MaxDelaysByAirline as (
    select 
        Reporting_Airline,
        MAX(Avg_Departure_Delay) as Max_Avg_Departure_Delay
    from 
        AirlineAirportAvgDelays
    group by 
        Reporting_Airline
)
select
    substring_index(L_AIRLINE_ID.Name, ': ', 1) as Airline_Name,
    substring_index(L_AIRPORT_ID.Name, ': ', -1) AS Airport_Name,
    round(AirlineAirportAvgDelays.Avg_Departure_Delay, 4) AS Avg_Departure_Delay
from AirlineAirportAvgDelays
join MaxDelaysByAirline
on
    AirlineAirportAvgDelays.Reporting_Airline = MaxDelaysByAirline.Reporting_Airline
    and AirlineAirportAvgDelays.Avg_Departure_Delay = MaxDelaysByAirline.Max_Avg_Departure_Delay
join L_AIRLINE_ID
on AirlineAirportAvgDelays.Reporting_Airline = substring_index(L_AIRLINE_ID.Name, ': ', -1)
join L_AIRPORT_ID
on AirlineAirportAvgDelays.originAirportID = L_AIRPORT_ID.ID
order by Airline_Name;
# number of rows returned: 16
 
/*
Problem 6
Problem Formulation
1. Data Attributes in the result set:
	airport name, reason, number of cancellations
2. Data Attributes used in the condition:
	number of cancellations
3. Tables with relevant information:
	al_perf, L_AIRPORT_ID, L_CANCELATION
4. Useful attributes in the tables:
	OriginAirportID, CancellationCode, L_AIRPORT_ID.Name, L_CANCELATION.Reason
5. Joining the tables:
	MostFrequentReasons.OriginAirportID = L_AIRPORT_ID.ID
	MostFrequentReasons.CancellationCode = L_CANCELATION.Code
6. Conditions to be satisfied:
	maximum number of cancellations due to a particular reason
*/
with CancellationCounts as (
    select 
        al_perf.OriginAirportID,
        al_perf.CancellationCode,
        count(*) AS Cancelation_Count
    from al_perf
    where al_perf.Cancelled = 1
    group by al_perf.OriginAirportID, al_perf.CancellationCode
),
MostFrequentReasons as (
    select 
        originAirportID,
        CancellationCode,
        Cancelation_Count,
        rank() over (partition by originAirportID order by Cancelation_Count desc) as Rank_Cancellations
    from CancellationCounts
)
select
    substring_index(L_AIRPORT_ID.Name, ': ', -1) as Airport_Name,
    L_CANCELATION.Reason as Most_Frequent_Reason,
    MostFrequentReasons.Cancelation_Count as Number_Of_Cancelations
from MostFrequentReasons
join L_AIRPORT_ID
on MostFrequentReasons.OriginAirportID = L_AIRPORT_ID.ID
join L_CANCELATION
on MostFrequentReasons.CancellationCode = L_CANCELATION.Code
where MostFrequentReasons.Rank_Cancellations = 1
order by Number_Of_Cancelations DESC;
# number of rows returned: 276

/*
Problem 7
Problem Formulation
1. Data Attributes in the result set:
	date, number of flights, rolling average
2. Tables with relevant information:
	al_perf
3. Useful attributes in the tables:
	FlightDate, count(*)
4. Conditions to be satisfied:
	window = preceding 3
*/
select 
    FlightDate,
    count(*) as Total_Flights,
    round(avg(count(*)) over (
        order by FlightDate 
        rows between 3 preceding and 1 preceding
    ), 2) as Avg_Flights_Preceding_3_Days
from al_perf
group by FlightDate
order by FlightDate;
# number of rows returned: 31
