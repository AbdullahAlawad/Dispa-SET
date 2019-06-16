$Title UCM model

$eolcom //
Option threads=10;
Option IterLim=1000000000;
Option ResLim = 10000000000;
*Option optca=0.0;

$onecho > cplex.opt
lpmethod 4
startalg 4
advind 0
scaind 1
$offecho

OPTION MIP = cplex;

// Reduce .lst file size

// Turn off the listing of the input file
$offlisting
$offlog

// Turn off the listing and cross-reference of the symbols used
$offsymxref offsymlist

option
    limrow = 0,     // equations listed per block
    limcol = 0,     // variables listed per block
    solprint = off,     // solver's solution output printed
    sysout = off;       // solver's system output printed



*===============================================================================
*Definition of the dataset-related options
*===============================================================================

* Print results to excel files (0 for no, 1 for yes)
$set Verbose 0

* Set debug mode. !! This breaks the loop and requires a debug.gdx file !!
* (0 for no, 1 for yes)
$set Debug 0

* Print results to excel files (0 for no, 1 for yes)
$set PrintResults 0

* Name of the input file (Ideally, stick to the default Input.gdx)
*$set InputFileName Input.gdx
$set InputFileName Inputs.gdx

* Definition of the equations that will be present in LP or MIP
* (1 for LP 0 for MIP TC)
$setglobal LPFormulation 0
* Flag to retrieve status or not
* (1 to retrieve 0 to not)
$setglobal RetrieveStatus 0

*===============================================================================
*Definition of   sets and parameters
*===============================================================================
SETS
mk               Markets
n                Nodes
KSA(n)           Subset of Nodes that belong to the country KSA
l                Lines
u                Units
t                Generation technologies
tr(t)            Renewable generation technologies
f                Fuel types
p                Pollutants
s(u)             Storage Units (with reservoir)
chp(u)           CHP units
h                Hours
i(h)             Subset of simulated hours for one iteration
z(h)             Subset of all simulated hours
;

Alias(mk,mkmk);
Alias(n,nn);
Alias(l,ll);
Alias(u,uu);
Alias(t,tt);
Alias(f,ff);
Alias(p,pp);
Alias(h,hh);
Alias(i,ii);

*Parameters as defined in the input file
PARAMETERS
AvailabilityFactor(u,h)          [%]      Availability factor
CommittedInitial(u)              [n.a.]   Initial committment status
Config                           *[n.a.]  Specifies rolling horizon & look ahead period & first day & last day
*CostCurtailment(n,h)             [$\MW]  Curtailment costs
CostFixed(u)                     [$\h]    Fixed costs
CostRampUp(u)                    [$\MW\h] Ramp-up costs
CostRampDown(u)                  [$\MW\h] Ramp-down costs
CostShutDown(u)                  [$\u]    Shut-down costs
CostStartUp(u)                   [$\u]    Start-up costs
CostVariable(u,h)                [$\MW]   Variable costs
CostVariableB(u,h)               [$\MW]   Alternative Variable costs (e.g. fuel prices)
CostHeatSlack(chp,h)             [$\MWh]  Cost of supplying heat via other means
CostLoadShedding(n,h)            [$\MWh] Cost of load shedding
Curtailment(n)                   [n.a]    Curtailment allowed or not {1 0} at node n
Demand(mk,n,h)                   [MW]     Demand
Efficiency(u)                    [%]      Efficiency
EmissionMaximum(n,p)             [tP]     Emission limit
EmissionRate(u,p)                [tP\MWh] P emission rate
FlowMaximum(l,h)                 [MW]     Line limits
FlowMinimum(l,h)                 [MW]     Minimum flow
Fuel(u,f)                        [n.a.]   Fuel type {1 0}
FuelPricePerZone                 *[$\MWh]  Average international & subsidized prices for each fuel in each zone
HeatDemand(chp,h)                [MWh\u]  Heat demand profile for chp units
LineNode(l,n)                    [n.a.]   Incidence matrix {-1 +1}
LoadShedding(n,h)                [MW]   Load shedding capacity
Location(u,n)                    [n.a.]   Location {1 0}
Markup(u,h)                      [$\MW]   Markup
OutageFactor(u,h)                [%]      Outage Factor (100% = full outage)
PartLoadMin(u)                   [%]      Minimum part load
PowerCapacity(u)                 [MW\u]     Installed capacity
PowerInitial(u)                  [MW\u]     Power output before initial period
PowerMinStable(u)                [MW\u]     Minimum power output
PriceTransmission(l,h)           [$\MWh]  Transmission price
RampDownMaximum(u)               [MW\h\u]   Ramp down limit
RampShutDownMaximum(u)           [MW\h\u]   Shut-down ramp limit
RampStartUpMaximum(u)            [MW\h\u]   Start-up ramp limit
RampStartUpMaximumH(u,h)         [MW\h\u]   Start-up ramp limit - Clustered formulation
RampShutDownMaximumH(u,h)        [MW\h\u]   Shut-down ramp limit - Clustered formulation
RampUpMaximum(u)                 [MW\h\u]   Ramp up limit
Reserve(t)                       [n.a.]   Reserve technology {1 0}
Technology(u,t)                  [n.a.]   Technology type {1 0}
TimeDownMinimum(u)               [h]      Minimum down time
TimeUpMinimum(u)                 [h]      Minimum up time
$If %RetrieveStatus% == 1 CommittedCalc(u,z)               [n.a.]   Committment status as for the MILP
Nunits(u)                        [n.a.]   Number of units inside the cluster (upper bound value for integer variables)
K_QuickStart(n)                      [n.a.]   Part of the reserve that can be provided by offline quickstart units
QuickStartPower(u,h)            [MW\h\u]   Available max capacity in tertiary regulation up from fast-starting power plants - TC formulation
;


*Parameters as used within the loop
PARAMETERS
CostLoadShedding(n,h)            [$\MW]  Value of lost load
LoadMaximum(u,h)                 [%]     Maximum load given AF and OF
PowerMustRun(u,h)                [MW]    Minimum power output
;

* Scalar variables necessary to the loop:
scalar FirstHour,LastHour,LastKeptHour,day,ndays,failed;
FirstHour = 1;

*===============================================================================
*Data import
*===============================================================================

$gdxin %inputfilename%

$LOAD mk
$LOAD n
$LOAD KSA
$LOAD l
$LOAD u
$LOAD t
$LOAD tr
$LOAD f
$LOAD p
$LOAD s
$LOAD chp
$LOAD h
$LOAD z
$LOAD AvailabilityFactor
$LOAD Config
$LOAD CostFixed
$LOAD CostHeatSlack
$LOAD CostLoadShedding
$LOAD CostShutDown
$LOAD CostStartUp
$LOAD CostVariable
$LOAD CostVariableB
$LOAD Curtailment
$LOAD Demand
$LOAD Efficiency
$LOAD EmissionMaximum
$LOAD EmissionRate
$LOAD FlowMaximum
$LOAD FlowMinimum
$LOAD Fuel
$LOAD FuelPricePerZone
$LOAD HeatDemand
$LOAD LineNode
$LOAD LoadShedding
$LOAD Location
$LOAD Markup
$LOAD Nunits
$LOAD OutageFactor
$LOAD PowerCapacity
$LOAD PowerInitial
$LOAD PartLoadMin
$LOAD PriceTransmission
$LOAD RampDownMaximum
$LOAD RampShutDownMaximum
$LOAD RampStartUpMaximum
$LOAD RampUpMaximum
$LOAD Reserve
$LOAD Technology
$LOAD TimeDownMinimum
$LOAD TimeUpMinimum
$LOAD CostRampUp
$LOAD CostRampDown
$If %RetrieveStatus% == 1 $LOAD CommittedCalc
;

$If %Verbose% == 0 $goto skipdisplay

Display
mk,
n,
KSA,
l,
u,
t,
tr,
f,
p,
h,
AvailabilityFactor,
Config,
CostFixed,
CostShutDown,
CostStartUp,
CostRampUp,
CostVariable,
CostVariableB,
Demand,
Efficiency,
EmissionMaximum,
EmissionRate,
FlowMaximum,
FlowMinimum,
FuelPrice,
Fuel,
LineNode,
Location,
LoadShedding,
Markup,
OutageFactor,
PartLoadMin,
PowerCapacity,
PowerInitial,
PriceTransmission,
RampDownMaximum,
RampShutDownMaximum,
RampStartUpMaximum,
RampUpMaximum,
Reserve,
Technology,
TimeDownMinimum,
TimeUpInitial,
TimeUpMinimum
$If %RetrieveStatus% == 1 , CommittedCalc
;

$label skipdisplay

*===============================================================================
*Definition of variables
*===============================================================================
VARIABLES
Committed(u,h)             [n.a.]  Unit committed at hour h {1 0}
StartUp(u,h)        [n.a.]  Unit start up at hour h {1 0}  or integer
ShutDown(u,h)       [n.a.]  Unit shut down at hour h {1 0} or integer
;

$If %LPFormulation% == 1 POSITIVE VARIABLES Committed (u,h) ; Committed.UP(u,h) = 1 ;
$If not %LPFormulation% == 1 INTEGER VARIABLES Committed (u,h), StartUp(u,h), ShutDown(u,h) ; Committed.UP(u,h) = Nunits(u) ; StartUp.UP(u,h) = Nunits(u) ; ShutDown.UP(u,h) = Nunits(u) ;

POSITIVE VARIABLES
CostStartUpH(u,h)          [EUR]   Cost of starting up
CostShutDownH(u,h)         [EUR]   cost of shutting down
CostRampUpH(u,h)           [EUR]   Ramping cost
CostRampDownH(u,h)         [EUR]   Ramping cost
CurtailedPower(n,h)        [MW]    Curtailed power at node n
Flow(l,h)                  [MW]    Flow through lines
Power(u,h)                 [MW]    Power output
PowerN(u,n,h)              [MW]    The portion of power unit output to supply certain node
PowerMaximum(u,h)          [MW]    Power output
PowerMinimum(u,h)          [MW]    Power output
ShedLoad(n,h)              [MW]    Shed load
LL_MaxPower(n,h)           [MW]    Deficit in terms of maximum power
LL_RampUp(u,h)             [MW]    Deficit in terms of ramping up for each plant
LL_RampDown(u,h)           [MW]    Deficit in terms of ramping down
LL_MinPower(n,h)           [MW]    Power exceeding the demand
LL_2U(n,h)                 [MW]    Deficit in reserve up
LL_3U(n,h)                 [MW]    Deficit in reserve up - non spinning
LL_2D(n,h)                 [MW]    Deficit in reserve down
SystemCost(n,h)              [EUR]   Hourly system cost
Reserve_2U(u,h)            [MW]    Spinning reserve up
Reserve_2D(u,h)            [MW]    Spinning reserve down
Reserve_3U(u,h)            [MW]    Non spinning quick start reserve up
;

free variable
SystemCostD               ![$]   Total system cost for one optimization period
;

*===============================================================================
*Assignment of initial values
*===============================================================================

*Initial commitment status
CommittedInitial(u)=0;
CommittedInitial(u)$(PowerInitial(u)>0)=1;

* Definition of the minimum stable load:
PowerMinStable(u) = PartLoadMin(u)*PowerCapacity(u);

LoadMaximum(u,h)= AvailabilityFactor(u,h)*(1-OutageFactor(u,h));

* parameters for clustered formulation (quickstart is defined as the capability to go to minimum power in 15 min)
QuickStartPower(u,h) = 0;
QuickStartPower(u,h)$(RampStartUpMaximum(u)>=PowerMinStable(u)*4) = PowerCapacity(u)*LoadMaximum(u,h);
RampStartUpMaximumH(u,h) = min(PowerCapacity(u)*LoadMaximum(u,h),max(RampStartUpMaximum(u),PowerMinStable(u),QuickStartPower(u,h)));
RampShutDownMaximumH(u,h) = min(PowerCapacity(u)*LoadMaximum(u,h),max(RampShutDownMaximum(u),PowerMinStable(u)));

PowerMustRun(u,h)=PowerMinStable(u)*LoadMaximum(u,h);
PowerMustRun(u,h)$(sum(tr,Technology(u,tr))>=1 and smin(n,Location(u,n)*(1-Curtailment(n)))=1) = PowerCapacity(u)*LoadMaximum(u,h);

* Part of the reserve that can be provided by offline quickstart units:
K_QuickStart(n) = Config("QuickStartShare","val");

$If %Verbose% == 1 Display RampStartUpMaximum, RampShutDownMaximum, CommittedInitial, FlexibilityUp, FlexibilityDown;

$offorder

*===============================================================================
*Declaration and definition of equations
*===============================================================================
EQUATIONS
******
EQ_Power_Output_Split
EQ_Power_origin
EQ_Objective_function
EQ_Commitment
EQ_MinUpTime
EQ_MinDownTime
EQ_RampUp_TC
EQ_RampDown_TC
EQ_CostStartUp
EQ_CostShutDown
EQ_CostRampUp
EQ_CostRampDown
EQ_Demand_balance_DA
EQ_Demand_balance_2U
EQ_Demand_balance_3U
EQ_Demand_balance_2D
EQ_Power_must_run
EQ_Power_available
EQ_Reserve_2U_capability
EQ_Reserve_2D_capability
EQ_Reserve_3U_capability
EQ_SystemCost
EQ_Emission_limits
EQ_Flow_limits_lower
EQ_Flow_limits_upper
EQ_Flow_limits_upper1
EQ_Flow_limits_upper1i
EQ_Flow_limits_upper2
EQ_Flow_limits_upper2i
EQ_Flow_limits_upper3
EQ_Flow_limits_upper3i
EQ_Flow_limits_upper4
EQ_Flow_limits_upper4i
EQ_Flow_limits_upper5
EQ_Flow_limits_upper5i
EQ_Flow_limits_upper6
EQ_Flow_limits_upper6i
EQ_Flow_limits_upper7
EQ_Flow_limits_upper7i
EQ_Flow_limits_upper8
EQ_Flow_limits_upper8i
EQ_Flow_limits_upper9
EQ_Flow_limits_upper9i
EQ_Force_Commitment
EQ_Force_DeCommitment
EQ_LoadShedding
$If %RetrieveStatus% == 1 EQ_CommittedCalc
;

$If %RetrieveStatus% == 0 $goto skipequation

EQ_CommittedCalc(u,z)..
         Committed(u,z)
         =E=
         CommittedCalc(u,z)
;

$label skipequation
*******
EQ_Power_Output_Split(u,i)..
         Power(u,i) =E= sum(n,PowerN(u,n,i))
;

*Objective function
*(NODE cost = operation cost for units of the NODE generating power for local demand + operation cost for units of the NODE generating power for EXPORTS)
*EQ_SystemCost(n,i)..
*         SystemCost(n,i)
*         =E=
*         sum(u$(Location(u,n) EQ 1),CostFixed(u)*Committed(u,i))
*         +sum(u$(Location(u,n) EQ 1),CostStartUpH(u,i) + CostShutDownH(u,i))
*         +sum(u$(Location(u,n) EQ 1),CostRampUpH(u,i) + CostRampDownH(u,i))
*         +sum((u,nn)$(Location(u,n) EQ 1 and ord(n) eq ord(nn)),CostVariable(u,i) * PowerN(u,nn,i))
*         +(sum((u,nn)$(Location(u,n) EQ 1 and ord(n) NE ord(nn)),CostVariableB(u,i) * PowerN(u,nn,i)))$(not KSA(n))
*         +(sum((u,nn)$(Location(u,n) EQ 1 and ord(n) NE ord(nn) and not KSA(nn)),CostVariableB(u,i) * PowerN(u,nn,i)))$(KSA(n))
*         +(sum((u,nn)$(Location(u,n) EQ 1 and ord(n) NE ord(nn) and KSA(nn)),CostVariable(u,i) * PowerN(u,nn,i)))$(KSA(n))
*         +CostLoadShedding(n,i)*ShedLoad(n,i)
*         +100E3*(LostLoad_MaxPower(n,i)+LostLoad_MinPower(n,i))
*         +80E3*(LostLoad_Reserve2U(n,i)+LostLoad_Reserve2D(n,i))
*        +70E3*sum(u$(Location(u,n) EQ 1),LostLoad_RampUp(u,i)+LostLoad_RampDown(u,i))
*;

*(Node cost = operation cost for units of the NODE generating power for local demand + operation cost for units of the other nodes that are generating power IMPORTED to the NODE)
$ifthen [%LPFormulation% == 1]
EQ_SystemCost(n,i)..
         SystemCost(n,i)
         =E=
         sum(u$(Location(u,n) EQ 1),CostFixed(u)*Committed(u,i))
         +sum(u$(Location(u,n) EQ 1),CostRampUpH(u,i) + CostRampDownH(u,i))
         +sum(u$(Location(u,n) EQ 1),CostVariable(u,i) * PowerN(u,n,i))
         +(sum(u$(Location(u,n) EQ 0),CostVariableB(u,i) * PowerN(u,n,i)))$(not KSA(n))
         +(sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and not KSA(nn)),CostVariableB(u,i) * PowerN(u,n,i)))$(KSA(n))
         +(sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and KSA(nn)),CostVariable(u,i) * PowerN(u,n,i)))$(KSA(n))
         +CostLoadShedding(n,i)*ShedLoad(n,i)
         +Config("ValueOfLostLoad","val")*(LL_MaxPower(n,i)+LL_MinPower(n,i))
         +0.8*Config("ValueOfLostLoad","val")*(LL_2U(n,i)+LL_2D(n,i)+LL_3U(n,i))
         +0.7*Config("ValueOfLostLoad","val")*sum(u$(Location(u,n) EQ 1),LL_RampUp(u,i)+LL_RampDown(u,i))
;

$else
EQ_SystemCost(n,i)..
         SystemCost(n,i)
         =E=
         sum(u$(Location(u,n) EQ 1),CostFixed(u)*Committed(u,i))
         +sum(u$(Location(u,n) EQ 1),CostStartUpH(u,i) + CostShutDownH(u,i))
         +sum(u$(Location(u,n) EQ 1),CostRampUpH(u,i) + CostRampDownH(u,i))
         +sum(u$(Location(u,n) EQ 1),CostVariable(u,i) * PowerN(u,n,i))
         +(sum(u$(Location(u,n) EQ 0),CostVariableB(u,i) * PowerN(u,n,i)))$(not KSA(n))
         +(sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and not KSA(nn)),CostVariableB(u,i) * PowerN(u,n,i)))$(KSA(n))
         +(sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and KSA(nn)),CostVariable(u,i) * PowerN(u,n,i)))$(KSA(n))
         +CostLoadShedding(n,i)*ShedLoad(n,i)
         +Config("ValueOfLostLoad","val")*(LL_MaxPower(n,i)+LL_MinPower(n,i))
         +0.8*Config("ValueOfLostLoad","val")*(LL_2U(n,i)+LL_2D(n,i)+LL_3U(n,i))
         +0.7*Config("ValueOfLostLoad","val")*sum(u$(Location(u,n) EQ 1),LL_RampUp(u,i)+LL_RampDown(u,i))
;

$endIf
;

EQ_Objective_function..
         SystemCostD
         =E=
         sum((n,i),SystemCost(n,i)) +sum((l,i),PriceTransmission(l,i)*Flow(l,i))
;

* 3 binary commitment status
EQ_Commitment(u,i)..
         Committed(u,i)-CommittedInitial(u)$(ord(i) = 1)-Committed(u,i-1)$(ord(i) > 1)
         =E=
         StartUp(u,i) - ShutDown(u,i)
;

* minimum up time
EQ_MinUpTime(u,i)..
         sum(ii$( (ord(ii) >= ord(i) - TimeUpMinimum(u)) and (ord(ii) <= ord(i)) ), StartUp(u,ii))
         + sum(h$( (ord(h) >= FirstHour + ord(i) - TimeUpMinimum(u) -1) and (ord(h) < FirstHour)),StartUp.L(u,h))
         =L=
         Committed(u,i)
;

* minimum down time
EQ_MinDownTime(u,i)..
         sum(ii$( (ord(ii) >= ord(i) - TimeDownMinimum(u)) and (ord(ii) <= ord(i)) ), ShutDown(u,ii))
         + sum(h$( (ord(h) >= FirstHour + ord(i) - TimeDownMinimum(u) -1) and (ord(h) < FirstHour)),ShutDown.L(u,h))
         =L=
         Nunits(u)-Committed(u,i)
;

* ramp up constraints
EQ_RampUp_TC(u,i)$(sum(tr,Technology(u,tr))=0)..
         - Power(u,i-1)$(ord(i) > 1) - PowerInitial(u)$(ord(i) = 1) + Power(u,i)
         =L=
         (Committed(u,i) - StartUp(u,i)) * RampUpMaximum(u) + RampStartUpMaximumH(u,i) * StartUp(u,i) - PowerMustRun(u,i) * ShutDown(u,i) + LL_RampUp(u,i)
;

* ramp down constraints
EQ_RampDown_TC(u,i)$(sum(tr,Technology(u,tr))=0)..
         Power(u,i-1)$(ord(i) > 1) + PowerInitial(u)$(ord(i) = 1) - Power(u,i)
         =L=
         (Committed(u,i) - StartUp(u,i)) * RampDownMaximum(u) + RampShutDownMaximumH(u,i) * ShutDown(u,i) - PowerMustRun(u,i) * StartUp(u,i) + LL_RampDown(u,i)
;

* Start up cost
EQ_CostStartUp(u,i)$(CostStartUp(u) <> 0)..
         CostStartUpH(u,i)
         =E=
         CostStartUp(u)*StartUp(u,i)
;

* Start up cost
EQ_CostShutDown(u,i)$(CostShutDown(u) <> 0)..
         CostShutDownH(u,i)
         =E=
         CostShutDown(u)*ShutDown(u,i)
;

EQ_CostRampUp(u,i)$(CostRampUp(u) <> 0)..
         CostRampUpH(u,i)
         =G=
         CostRampUp(u)*(Power(u,i)-PowerInitial(u)$(ord(i) = 1)-Power(u,i-1)$(ord(i) > 1))
;

EQ_CostRampDown(u,i)$(CostRampDown(u) <> 0)..
         CostRampDownH(u,i)
         =G=
         CostRampDown(u)*(PowerInitial(u)$(ord(i) = 1)+Power(u,i-1)$(ord(i) > 1)-Power(u,i))
;

*******
*Hourly demand balance in the day-ahead market for each node
*EQ_Demand_balance_DA(n,i)..
*         sum(u,Power(u,i)*Location(u,n))
*          +sum(l,Flow(l,i)*LineNode(l,n))
*         =E=
*         Demand("DA",n,i)
*         -ShedLoad(n,i)
*         -LostLoad_MaxPower(n,i)
*         +LostLoad_MinPower(n,i)
*;

EQ_Demand_balance_DA(n,i)..
         sum(u$(Location(u,n) EQ 1), Power(u,i))
*          sum(u$(Location(u,n) EQ 1), PowerN(u,n,i))
         +sum(l$(LineNode(l,n) EQ 1), Flow(l,i))
         -sum(l$(LineNode(l,n) EQ -1), Flow(l,i))
         =E=
         Demand("DA",n,i)
         -ShedLoad(n,i)
         -LL_MaxPower(n,i)
         +LL_MinPower(n,i)
;

EQ_Power_origin(n,i)..
*         sum((u,nn)$(Location(u,n) NE 1 and ord(n) EQ ord(nn)),PowerN(u,nn,i))
          sum(u$(Location(u,n) NE 1),PowerN(u,n,i))
         -sum((u,nn)$(Location(u,n) EQ 1 and ord(n) NE ord(nn)),PowerN(u,nn,i))
         =E=
         sum(l$(LineNode(l,n) EQ 1), Flow(l,i))
         -sum(l$(LineNode(l,n) EQ -1), Flow(l,i))
;

*Hourly demand balance in the upwards spinning reserve market for each node
EQ_Demand_balance_2U(n,i)..
         sum((u,t),Reserve_2U(u,i)*Technology(u,t)*Reserve(t)*Location(u,n))
         =G=
         +Demand("2U",n,i)*(1-K_QuickStart(n))
         -LL_2U(n,i)
;

*Hourly demand balance in the upwards non-spinning reserve market for each node
EQ_Demand_balance_3U(n,i)..
         sum((u,t),(Reserve_2U(u,i) + Reserve_3U(u,i))*Technology(u,t)*Reserve(t)*Location(u,n))
         =G=
         +Demand("2U",n,i)
         -LL_3U(n,i)
;

*Hourly demand balance in the downwards reserve market for each node
EQ_Demand_balance_2D(n,i)..
         sum((u,t),Reserve_2D(u,i)*Technology(u,t)*Reserve(t)*Location(u,n))
         =G=
         Demand("2D",n,i)
         -LL_2D(n,i)
;

EQ_Reserve_2U_capability(u,i)..
         Reserve_2U(u,i)
         =L=
         PowerCapacity(u)*LoadMaximum(u,i)*Committed(u,i) - Power(u,i)
;

EQ_Reserve_2D_capability(u,i)..
         Reserve_2D(u,i)
         =L=
         (Power(u,i) - PowerMustRun(u,i) * Committed(u,i))
;

EQ_Reserve_3U_capability(u,i)$(QuickStartPower(u,i) > 0)..
         Reserve_3U(u,i)
         =L=
         (Nunits(u)-Committed(u,i))*QuickStartPower(u,i)
;

*Minimum power output is above the must-run output level for each unit in all periods
*******
EQ_Power_must_run(u,i)..
         PowerMustRun(u,i) * Committed(u,i)
         =L=
         Power(u,i)
;

*Maximum power output is below the available capacity
EQ_Power_available(u,i)..
         Power(u,i)
         =L=
         PowerCapacity(u)
                 *LoadMaximum(u,i)
                         *Committed(u,i)
;

*Total emissions are capped
EQ_Emission_limits(n,i,p)..
         sum(u,Power(u,i)*EmissionRate(u,p)*Location(u,n))
         =L=
         EmissionMaximum(n,p)
;

*Flows are above minimum values
EQ_Flow_limits_lower(l,i)..
         FlowMinimum(l,i)
         =L=
         Flow(l,i)
;

*Flows are below maximum values
EQ_Flow_limits_upper(l,i)..
         Flow(l,i)
         =L=
         FlowMaximum(l,i)
;

*Flows are below maximum values of injection edges of each country
EQ_Flow_limits_upper1(i)..
         Flow("KW -> SA_EOA",i) + Flow("BA -> SA_EOA",i) + Flow("QA -> SA_EOA",i) + Flow("UAE -> SA_EOA",i)  =L= 1800
;
*+ Flow("OM -> SA_EOA",i)
EQ_Flow_limits_upper1i(i)..
         Flow("SA_EOA -> KW",i) + Flow("SA_EOA -> BA",i) + Flow("SA_EOA -> QA",i) + Flow("SA_EOA -> UAE",i)  =L= 1800
;
*+ Flow("SA_EOA -> OM",i)
EQ_Flow_limits_upper2(i)..
         Flow("SA_EOA -> KW",i) + Flow("BA -> KW",i) + Flow("QA -> KW",i) + Flow("UAE -> KW",i)  =L= 1550
;
*+ Flow("OM -> KW",i)
EQ_Flow_limits_upper2i(i)..
         Flow("KW -> SA_EOA",i) + Flow("KW -> BA",i) + Flow("KW -> QA",i) + Flow("KW -> UAE",i)  =L= 1550
;
*+ Flow("KW -> OM",i)
EQ_Flow_limits_upper3(i)..
         Flow("SA_EOA -> BA",i) + Flow("KW -> BA",i) + Flow("QA -> BA",i) + Flow("UAE -> BA",i)  =L= 1360
;
*+ Flow("OM -> BA",i)
EQ_Flow_limits_upper3i(i)..
         Flow("BA -> SA_EOA",i) + Flow("BA -> KW",i) + Flow("BA -> QA",i) + Flow("BA -> UAE",i)  =L= 1360
;
*+ Flow("BA -> OM",i)
EQ_Flow_limits_upper4(i)..
         Flow("SA_EOA -> QA",i) + Flow("KW -> QA",i) + Flow("BA -> QA",i) + Flow("UAE -> QA",i)  =L= 1500
;
*+ Flow("OM -> QA",i)
EQ_Flow_limits_upper4i(i)..
         Flow("QA -> SA_EOA",i) + Flow("QA -> KW",i) + Flow("QA -> BA",i) + Flow("QA -> UAE",i)  =L= 1500
;
*+ Flow("QA -> OM",i)
EQ_Flow_limits_upper5(i)..
         Flow("SA_EOA -> UAE",i) + Flow("KW -> UAE",i) + Flow("BA -> UAE",i) + Flow("QA -> UAE",i) =L= 1550
;
EQ_Flow_limits_upper5i(i)..
         Flow("UAE -> SA_EOA",i) + Flow("UAE -> KW",i) + Flow("UAE -> BA",i) + Flow("UAE -> QA",i) =L= 1550
;
EQ_Flow_limits_upper6(i)..
          Flow("UAE -> OM",i) =L= 400
;
*Flow("SA_EOA -> OM",i) + Flow("KW -> OM",i) + Flow("BA -> OM",i) + Flow("QA -> OM",i) +
EQ_Flow_limits_upper6i(i)..
          Flow("OM -> UAE",i) =L= 400
;
*Flow("OM -> SA_EOA",i) + Flow("OM -> KW",i) + Flow("OM -> BA",i) + Flow("OM -> QA",i) +
*Flows are below maximum values of some edges (transmission lines) that are shared between GCC countries
*transmission line between Salwa and UAE
EQ_Flow_limits_upper7(i)..
          Flow("SA_EOA -> UAE",i) + Flow("KW -> UAE",i) + Flow("BA -> UAE",i) + Flow("QA -> UAE",i) =L= 1550
;
*Flow("SA_EOA -> OM",i) + Flow("KW -> OM",i) + Flow("BA -> OM",i) + Flow("QA -> OM",i) +
EQ_Flow_limits_upper7i(i)..
         Flow("UAE -> QA",i)  + Flow("UAE -> BA",i) +  Flow("UAE -> SA_EOA",i) +  Flow("UAE -> KW",i)  =L= 1550
;
*+ Flow("OM -> QA",i) + Flow("OM -> BA",i) + Flow("OM -> SA_EOA",i) + Flow("OM -> KW",i)
*transmission line between Ghunan and Salwa
EQ_Flow_limits_upper8(i)..
         Flow("SA_EOA -> QA",i) + Flow("KW -> QA",i) + Flow("BA -> QA",i) + Flow("SA_EOA -> UAE",i) + Flow("KW -> UAE",i) + Flow("BA -> UAE",i)  =L= 1500
;
*+ Flow("SA_EOA -> OM",i) + Flow("KW -> OM",i) + Flow("BA -> OM",i)
EQ_Flow_limits_upper8i(i)..
         Flow("QA -> KW",i) + Flow("UAE -> KW",i)  + Flow("QA -> SA_EOA",i) + Flow("UAE -> SA_EOA",i)  + Flow("QA -> BA",i) + Flow("UAE -> BA",i)  =L= 1500
;
*+ Flow("OM -> KW",i) + Flow("OM -> SA_EOA",i) + Flow("OM -> BA",i)
*transmission line between Alfadhili and Ghunan
EQ_Flow_limits_upper9(i)..
         Flow("BA -> KW",i) + Flow("QA -> KW",i) + Flow("UAE -> KW",i)  + Flow("BA -> SA_EOA",i) + Flow("QA -> SA_EOA",i) + Flow("UAE -> SA_EOA",i)  =L= 1500
;
*+ Flow("OM -> KW",i) + Flow("OM -> SA_EOA",i)
EQ_Flow_limits_upper9i(i)..
         Flow("SA_EOA -> BA",i) + Flow("KW -> BA",i) + Flow("SA_EOA -> QA",i) + Flow("KW -> QA",i) + Flow("SA_EOA -> UAE",i) + Flow("KW -> UAE",i)  =L= 1500
;
*+ Flow("SA_EOA -> OM",i) + Flow("KW -> OM",i)

*Force Unit commitment/decommitment:
* E.g: renewable units with AF>0 must be committed
EQ_Force_Commitment(u,i)$((sum(tr,Technology(u,tr))>=1 and LoadMaximum(u,i)>0) or (ord(i)=4 and ord(u)=129))..
         Committed(u,i)
         =E=
         1;

* E.g: renewable units with AF=0 must be decommitted
EQ_Force_DeCommitment(u,i)$(LoadMaximum(u,i)=0 or ord(u)=200)..
         Committed(u,i)
         =E=
         0;

*Load shedding
EQ_LoadShedding(n,i)..
         ShedLoad(n,i)
         =L=
         LoadShedding(n,i)
;

*===============================================================================
*Definition of models
*===============================================================================
MODEL UCM_SIMPLE /
EQ_Power_Output_Split,
EQ_Objective_function,
EQ_Power_origin,
$If not %LPFormulation% == 1 EQ_CostStartUp,
$If not %LPFormulation% == 1 EQ_CostShutDown,
$If %LPFormulation% == 1 EQ_CostRampUp,
$If %LPFormulation% == 1 EQ_CostRampDown,
EQ_Commitment,
$If not %LPFormulation% == 1 EQ_MinUpTime,
$If not %LPFormulation% == 1 EQ_MinDownTime,
EQ_RampUp_TC,
EQ_RampDown_TC,
EQ_Demand_balance_DA,
EQ_Demand_balance_2U,
EQ_Demand_balance_2D,
EQ_Demand_balance_3U,
$If not %LPFormulation% == 1 EQ_Power_must_run,
EQ_Power_available,
EQ_Reserve_2U_capability,
EQ_Reserve_2D_capability,
EQ_Reserve_3U_capability,
EQ_SystemCost,
*EQ_Emission_limits,
EQ_Flow_limits_lower,
EQ_Flow_limits_upper,
EQ_Flow_limits_upper1,
EQ_Flow_limits_upper1i,
EQ_Flow_limits_upper2,
EQ_Flow_limits_upper2i,
EQ_Flow_limits_upper3,
EQ_Flow_limits_upper3i,
EQ_Flow_limits_upper4,
EQ_Flow_limits_upper4i,
EQ_Flow_limits_upper5,
EQ_Flow_limits_upper5i,
EQ_Flow_limits_upper6,
EQ_Flow_limits_upper6i,
EQ_Flow_limits_upper7,
EQ_Flow_limits_upper7i,
EQ_Flow_limits_upper8,
EQ_Flow_limits_upper8i,
EQ_Flow_limits_upper9,
EQ_Flow_limits_upper9i,
EQ_Force_Commitment,
EQ_Force_DeCommitment,
EQ_LoadShedding,
$If %RetrieveStatus% == 1 EQ_CommittedCalc
/
;
UCM_SIMPLE.optcr = 0.01;
UCM_SIMPLE.optfile = 1;
UCM_SIMPLE.holdfixed  = 1;
*UCM_SIMPLE.epgap = 0.005
*UCM_SIMPLE.probe = 3
*UCM_SIMPLE.optfile=1;

*===============================================================================
*Solving loop
*===============================================================================

ndays = floor(card(h)/24);
if (Config("RollingHorizon LookAhead","day") > ndays -1, abort "The look ahead period is longer than the simulation length";);

* Some parameters used for debugging:
failed=0;
parameter CommittedInitial_dbg(u), PowerInitial_dbg(u);

*Fixing the initial guesses:
*PowerH.L(u,i)=PowerInitial(u);
*Committed.L(u,i)=CommittedInitial(u);

* Defining a parameter that records the solver status:
set  tmp   "tpm"  / "model", "solver" /  ;
parameter status(tmp,h);

$if %Debug% == 1 $goto DebugSection

display "OK";

scalar starttime;
set days /1,'ndays'/;
display days;
PARAMETER elapsed(days);

FOR(day = 1 TO ndays-Config("RollingHorizon LookAhead","day") by Config("RollingHorizon Length","day"),
         FirstHour = (day-1)*24+1;
         LastHour = min(card(h),FirstHour + (Config("RollingHorizon Length","day")+Config("RollingHorizon LookAhead","day")) * 24 - 1);
         LastKeptHour = LastHour - Config("RollingHorizon LookAhead","day") * 24;
         i(h) = no;
         i(h)$(ord(h)>=firsthour and ord(h)<=lasthour)=yes;
         display day,FirstHour,LastHour,LastKeptHour;

$If %Verbose% == 1   Display PowerInitial,CommittedInitial;

$If %LPFormulation% == 1          SOLVE UCM_SIMPLE USING LP MINIMIZING SystemCostD;
$If not %LPFormulation% == 1      SOLVE UCM_SIMPLE USING MIP MINIMIZING SystemCostD;

$If %Verbose% == 0 $goto skipdisplay2
$If %LPFormulation% == 1          Display EQ_Objective_function.M, EQ_CostRampUp.M, EQ_CostRampDown.M, EQ_Demand_balance_DA.M, EQ_Flow_limits_lower.M ;
$If not %LPFormulation% == 1      Display EQ_Objective_function.M, EQ_CostStartUp.M, EQ_CostShutDown.M, EQ_Commitment.M, EQ_MinUpTime.M, EQ_MinDownTime.M, EQ_RampUp_TC.M, EQ_RampDown_TC.M, EQ_Demand_balance_DA.M, EQ_Demand_balance_2U.M, EQ_Demand_balance_2D.M, EQ_Demand_balance_3U.M, EQ_Reserve_2U_capability.M, EQ_Reserve_2D_capability.M, EQ_Reserve_3U_capability.M, EQ_Power_must_run.M, EQ_Power_available.M, EQ_SystemCost.M, EQ_Flow_limits_lower.M, EQ_Flow_limits_upper.M, EQ_Force_Commitment.M, EQ_Force_DeCommitment.M, EQ_LoadShedding.M ;
$label skipdisplay2

         status("model",i) = UCM_SIMPLE.Modelstat;
         status("solver",i) = UCM_SIMPLE.Solvestat;

if(UCM_SIMPLE.Modelstat <> 1 and UCM_SIMPLE.Modelstat <> 8 and not failed, CommittedInitial_dbg(u) = CommittedInitial(u); PowerInitial_dbg(u) = PowerInitial(u);
                                                                           EXECUTE_UNLOAD "debug.gdx" day, status, CommittedInitial_dbg, PowerInitial_dbg;
                                                                           failed=1;);

         CommittedInitial(u)=sum(i$(ord(i)=LastKeptHour-FirstHour+1),Committed.L(u,i));
         PowerInitial(u) = sum(i$(ord(i)=LastKeptHour-FirstHour+1),Power.L(u,i));

*Loop variables to display after solving:
$If %Verbose% == 1 Display LastKeptHour,PowerInitial,CostStartUpH.L,CostShutDownH.L,CostRampUpH.L;

);

CurtailedPower.L(n,z)=sum(u,(Nunits(u)*PowerCapacity(u)*LoadMaximum(u,z)-Power.L(u,z))$(sum(tr,Technology(u,tr))>=1) * Location(u,n));

$If %Verbose% == 1 Display Flow.L,Power.L,Committed.L,ShedLoad.L,CurtailedPower.L,SystemCost.L,LL_MaxPower.L,LL_MinPower.L,LL_2U.L,LL_2D.L,LL_RampUp.L,LL_RampDown.L;

*===============================================================================
*Result export
*===============================================================================

PARAMETER
UnitCommitment(u,h)
PowerFlow(l,h)

NodeOutputCurtailedPower(n,h)
LostLoad_MaxPower(n,h)
LostLoad_MinPower(n,h)
LostLoad_2D(n,h)
LostLoad_2U(n,h)
LostLoad_3U(n,h)
LostLoad_RampUp(n,h)
LostLoad_RampDown(n,h)
TotalNodeOperationCost(n,h)
TotalNodeVariableCost(n,h)
TotalKSAVariableCost(h)
NetNodeVariableCost(n,h)
NetKSAVariableCost(h)
ElectricityNodePrice(n,h)
ElectricityNodePrice2(n,h)
ElectricityNodePrice3(n,h)
ElectricityKSAPrice(h)
ElectricityKSAPrice2(h)
ElectricityKSAPrice3(h)
NodeOutputShedLoad(n,h)
NodeShadowPrice(n,h)
TotalNodeDemand(n,h)
TotalKSADemand(h)

PowerFlowMaxLimit(l,h)
PowerFlowMinLimit(l,h)

UnitOutputPower(u,h)
UnitOutputPowerInside(u,h)
UnitOutputPowerOutside(u,h)
UnitOutputPowerForNode(u,n,h)
UnitFixedCost(u,h)
UnitStartUpCost(u,h)
UnitShutDownCost(u,h)
UnitRampUpCost(u,h)
UnitRampDownCost(u,h)
UnitVariableCost(u,n,h)
UnitOperationCost(u,n,h)

LocalOutputPower(n,h)
LocalOutputPowerCost(n,h)
KSALocalOutputPower(h)
KSALocalOutputPowerCost(h)

TotalImportedPower(n,h)
TotalImportedPowerCost(n,h)
NetImportedPower(n,h)
NetImportedPowerCost(n,h)
ImportedPowerFromNode(n,nn,h)
ImportedPowerFromNodeCost(n,nn,h)
NetImportedPowerFromNode(n,nn,h)
NetImportedPowerFromNodeCost(n,nn,h)
KSATotalImportedPower(h)
KSATotalImportedPowerCost(h)
KSANetImportedPower(h)
KSANetImportedPowerCost(h)
KSAImportedPowerFromNode(n,h)
KSAImportedPowerFromNodeCost(n,h)
KSANetImportedPowerFromNode(n,h)
KSANetImportedPowerFromNodeCost(n,h)

TotalExportedPower(n,h)
TotalExportedPowerCost(n,h)
NetExportedPower(n,h)
NetExportedPowerCost(n,h)
ExportedPowerToNode(n,nn,h)
ExportedPowerToNodeCost(n,nn,h)
NetExportedPowerToNode(n,nn,h)
NetExportedPowerToNodeCost(n,nn,h)
KSATotalExportedPower(h)
KSATotalExportedPowerCost(h)
KSANetExportedPower(h)
KSANetExportedPowerCost(h)
KSAExportedPowerToNode(n,h)
KSAExportedPowerToNodeCost(n,h)
KSANetExportedPowerToNode(n,h)
KSANetExportedPowerToNodeCost(n,h)

LineCongestion(l,h)
LineCongestion_KSA_GCC(h)
LineCongestion_KW_GCC(h)
LineCongestion_BA_GCC(h)
LineCongestion_QA_GCC(h)
LineCongestion_UAE_GCC(h)
LineCongestion_OM_GCC(h)
LineCongestion_UAE_Salwa(h)
LineCongestion_Ghunan_Salwa(h)
LineCongestion_Ghunan_Alfadhili(h)

TotalSystemCost(h)
NodeFuelPower(n,f,h)
KSAFuelPower(f,h)
NodeFuelPowerCost(n,f,h)
KSAFuelPowerCost(f,h)
NodeFuelConsumption(n,f,h)
KSAFuelConsumption(f,h)
NodeFuelCost(n,f,h)
KSAFuelCost(f,h)
NodeFuelGovSpending(n,f,h)
KSAFuelGovSpending(f,h)

NodeLocalFuelPowerCost(n,f,h)
KSALocalFuelPowerCost(f,h)

NodeFuelPowerExport(n,f,h)
NodeFuelPowerExportCost(n,f,h)
NodeFuelExport(n,f,h)
NodeFuelExportCost(n,f,h)
KSAFuelPowerExport(f,h)
KSAFuelPowerExportCost(f,h)
KSAFuelExport(f,h)
KSAFuelExportCost(f,h)

NodeFuelPowerImport(n,f,h)
NodeFuelPowerImportCost(n,f,h)
NodeFuelImport(n,f,h)
NodeFuelImportCost(n,f,h)
KSAFuelPowerImport(f,h)
KSAFuelPowerImportCost(f,h)
KSAFuelImport(f,h)
KSAFuelImportCost(f,h)
;
*Results about the entire system
TotalSystemCost(z)=sum(n,SystemCost.L(n,z));
UnitCommitment(u,z)=Committed.L(u,z);
PowerFlow(l,z)=Flow.L(l,z);
LineCongestion(l,z)= 1 $(EQ_Flow_limits_upper.m(l,z) NE 0);
LineCongestion_KSA_GCC(z) = 1 $(EQ_Flow_limits_upper1.m(z) NE 0 or EQ_Flow_limits_upper1i.m(z) NE 0);
LineCongestion_KW_GCC(z) = 1 $(EQ_Flow_limits_upper2.m(z) NE 0 or EQ_Flow_limits_upper2i.m(z) NE 0);
LineCongestion_BA_GCC(z) = 1 $(EQ_Flow_limits_upper3.m(z) NE 0 or EQ_Flow_limits_upper3i.m(z) NE 0);
LineCongestion_QA_GCC(z) = 1 $(EQ_Flow_limits_upper4.m(z) NE 0 or EQ_Flow_limits_upper4i.m(z) NE 0);
LineCongestion_UAE_GCC(z) = 1 $(EQ_Flow_limits_upper5.m(z) NE 0 or EQ_Flow_limits_upper5i.m(z) NE 0);
LineCongestion_OM_GCC(z) = 1 $(EQ_Flow_limits_upper6.m(z) NE 0 or EQ_Flow_limits_upper6i.m(z) NE 0);
LineCongestion_UAE_Salwa(z) = 1 $(EQ_Flow_limits_upper7.m(z) NE 0 or EQ_Flow_limits_upper7i.m(z) NE 0);
LineCongestion_Ghunan_Salwa(z) = 1 $(EQ_Flow_limits_upper8.m(z) NE 0 or EQ_Flow_limits_upper8i.m(z) NE 0);
LineCongestion_Ghunan_Alfadhili(z) = 1 $(EQ_Flow_limits_upper9.m(z) NE 0 or EQ_Flow_limits_upper9i.m(z) NE 0);

*Results about each node in the system
TotalNodeOperationCost(n,z)=SystemCost.L(n,z);
NodeOutputShedLoad(n,z) = ShedLoad.L(n,z);
NodeOutputCurtailedPower(n,z)= CurtailedPower.L(n,z);
TotalNodeDemand(n,z) = Demand("DA",n,z);
TotalKSADemand(z) = sum(n$(KSA(n)), Demand("DA",n,z));
LostLoad_MaxPower(n,z)  = LL_MaxPower.L(n,z);
LostLoad_MinPower(n,z)  = LL_MinPower.L(n,z);
LostLoad_2D(n,z) = LL_2D.L(n,z);
LostLoad_2U(n,z) = LL_2U.L(n,z);
LostLoad_3U(n,z) = LL_3U.L(n,z);
LostLoad_RampUp(n,z)    = sum(u,LL_RampUp.L(u,z)*Location(u,n));
LostLoad_RampDown(n,z)  = sum(u,LL_RampDown.L(u,z)*Location(u,n));


***generation cost for: GenerationForLocalDemand + imports
TotalNodeVariableCost(n,z)= sum(u$(Location(u,n) EQ 1), PowerN.L(u,n,z)*CostVariable(u,z))
                          + (sum(u$(Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariableB(u,z)))$(not KSA(n))
                          + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and not KSA(nn)),PowerN.L(u,n,z)*CostVariableB(u,z)))$(KSA(n))
                          + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and KSA(nn)),PowerN.L(u,n,z)*CostVariable(u,z)))$(KSA(n));

TotalKSAVariableCost(z)=sum((u,n)$(Location(u,n) EQ 1 and KSA(n)), PowerN.L(u,n,z)*CostVariable(u,z))
                          + sum((u,n,nn)$(Location(u,n) EQ 0 and KSA(n) and Location(u,nn) EQ 1 and KSA(nn)), PowerN.L(u,n,z)*CostVariable(u,z))
                          + (sum((u,n,nn)$(Location(u,n) EQ 0 and KSA(n) and Location(u,nn) EQ 1 and not KSA(nn)),PowerN.L(u,n,z)*CostVariableB(u,z)));

***generation cost for: GenerationForLocalDemand + imports - exports
NetNodeVariableCost(n,z)= sum(u$(Location(u,n) EQ 1), PowerN.L(u,n,z)*CostVariable(u,z))
                        + (sum(u$(Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariableB(u,z)))$(not KSA(n))
                        + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and not KSA(nn)),PowerN.L(u,n,z)*CostVariableB(u,z)))$(KSA(n))
                        + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and KSA(nn)),PowerN.L(u,n,z)*CostVariable(u,z)))$(KSA(n))
                        - (sum(u$(Location(u,n) EQ 1),(Power.L(u,z)-PowerN.L(u,n,z))*CostVariableB(u,z)))$(not KSA(n))
                        - (sum((u,nn)$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(KSA(n))
                        - (sum((u,nn)$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z)*CostVariable(u,z)))$(KSA(n));

NetKSAVariableCost(z)=sum((u,n)$(Location(u,n) EQ 1 and KSA(n)), PowerN.L(u,n,z)*CostVariable(u,z))
                          + sum((u,n,nn)$(Location(u,n) EQ 0 and KSA(n) and Location(u,nn) EQ 1 and KSA(nn)), PowerN.L(u,n,z)*CostVariable(u,z))
                          + (sum((u,n,nn)$(Location(u,n) EQ 0 and KSA(n) and Location(u,nn) EQ 1 and not KSA(nn)),PowerN.L(u,n,z)*CostVariableB(u,z)))
                          - sum((u,n,nn)$(Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and KSA(nn)), PowerN.L(u,nn,z)*CostVariable(u,z))
                          - sum((u,n,nn)$(Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and not KSA(nn)), PowerN.L(u,nn,z)*CostVariableB(u,z));

***Electricity nodal prices
** NodeShadowPrice = marginal cost at each node (dual variable for the balance constraint)
** ElectricityNodePrice = (cost of local generation + cost of imports) / (Demand)
** ElectricityNodePrice2 = (cost of local generation + cost of imports + cost of exports) / (Demand + Exports)
** ElectricityNodePrice3 = (cost of local generation + cost of exports) / (Demand - Imports + Exports)
NodeShadowPrice(n,z) = EQ_Demand_balance_DA.m(n,z);
ElectricityNodePrice(n,z)= ( sum(u$(Location(u,n) EQ 1), PowerN.L(u,n,z)*CostVariable(u,z))
                          + (sum(u$(Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariableB(u,z)))$(not KSA(n))
                          + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and not KSA(nn)),PowerN.L(u,n,z)*CostVariableB(u,z)))$(KSA(n))
                          + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and KSA(nn)),PowerN.L(u,n,z)*CostVariable(u,z)))$(KSA(n)) )
                          / ( Demand("DA",n,z) );
ElectricityNodePrice2(n,z)= ( sum(u$(Location(u,n) EQ 1), PowerN.L(u,n,z)*CostVariable(u,z))
                        + (sum(u$(Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariableB(u,z)))$(not KSA(n))
                        + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and not KSA(nn)),PowerN.L(u,n,z)*CostVariableB(u,z)))$(KSA(n))
                        + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and KSA(nn)),PowerN.L(u,n,z)*CostVariable(u,z)))$(KSA(n))
                        + (sum(u$(Location(u,n) EQ 1),(Power.L(u,z)-PowerN.L(u,n,z))*CostVariableB(u,z)))$(not KSA(n))
                        + (sum((u,nn)$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(KSA(n))
                        + (sum((u,nn)$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z)*CostVariable(u,z)))$(KSA(n)) )
                          / ( (Demand("DA",n,z)) + (sum(u$(Location(u,n) EQ 1),Power.L(u,z)-PowerN.L(u,n,z))) );
ElectricityNodePrice3(n,z)= ( sum(u$(Location(u,n) EQ 1), PowerN.L(u,n,z)*CostVariable(u,z))
                        + (sum(u$(Location(u,n) EQ 1),(Power.L(u,z)-PowerN.L(u,n,z))*CostVariableB(u,z)))$(not KSA(n))
                        + (sum((u,nn)$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(KSA(n))
                        + (sum((u,nn)$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z)*CostVariable(u,z)))$(KSA(n)) )
                          / ( (Demand("DA",n,z)) - (sum(u$(Location(u,n) EQ 0),PowerN.L(u,n,z))) + (sum(u$(Location(u,n) EQ 1),Power.L(u,z)-PowerN.L(u,n,z))) );
ElectricityKSAPrice(z)= ( sum(n$(KSA(n)), sum(u$(Location(u,n) EQ 1), PowerN.L(u,n,z)*CostVariable(u,z))
                       + (sum(u$(Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariableB(u,z)))$(not KSA(n))
                       + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and not KSA(nn)),PowerN.L(u,n,z)*CostVariableB(u,z)))$(KSA(n))
                       + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and KSA(nn)),PowerN.L(u,n,z)*CostVariable(u,z)))$(KSA(n))) )
                          / ( (sum(n$(KSA(n)), Demand("DA",n,z))) );
ElectricityKSAPrice2(z)= ( sum(n$(KSA(n)), sum(u$(Location(u,n) EQ 1), PowerN.L(u,n,z)*CostVariable(u,z))
                     + (sum(u$(Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariableB(u,z)))$(not KSA(n))
                     + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and not KSA(nn)),PowerN.L(u,n,z)*CostVariableB(u,z)))$(KSA(n))
                     + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and KSA(nn)),PowerN.L(u,n,z)*CostVariable(u,z)))$(KSA(n))
                     + (sum(u$(Location(u,n) EQ 1),(Power.L(u,z)-PowerN.L(u,n,z))*CostVariableB(u,z)))$(not KSA(n))
                     + (sum((u,nn)$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(KSA(n))
                     + (sum((u,nn)$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z)*CostVariable(u,z)))$(KSA(n))) )
                          / ( (sum(n$(KSA(n)), Demand("DA",n,z))) + (sum((u,n,nn)$(Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z))) );
ElectricityKSAPrice3(z)= ( sum(n$(KSA(n)), sum(u$(Location(u,n) EQ 1), PowerN.L(u,n,z)*CostVariable(u,z))
                     + (sum(u$(Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariableB(u,z)))$(not KSA(n))
                     + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(KSA(n))
                     + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and KSA(nn)),PowerN.L(u,nn,z)*CostVariable(u,z)))$(KSA(n)) )
                          / ( (sum(n$(KSA(n)), Demand("DA",n,z))) - (sum((u,n,nn)$(Location(u,n) EQ 0 and KSA(n) and Location(u,nn) EQ 1 and not KSA(nn)), PowerN.L(u,n,z))) +
                          (sum((u,n,nn)$(Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)))) );

*Results about dual variables of line limits constraint
PowerFlowMaxLimit(l,z)= EQ_Flow_limits_upper.m(l,z);
PowerFlowMinLimit(l,z)= EQ_Flow_limits_lower.m(l,z);

*Results about each power unit in the system
UnitOutputPower(u,z)=Power.L(u,z);
UnitOutputPowerInside(u,z)= sum(n$(Location(u,n) EQ 1),PowerN.L(u,n,z));
UnitOutputPowerOutside(u,z)= sum(n$(Location(u,n) EQ 0),PowerN.L(u,n,z));
UnitOutputPowerForNode(u,n,z)= PowerN.L(u,n,z);
UnitFixedCost(u,z)= CostFixed(u)*Committed.L(u,z);
UnitStartUpCost(u,z)= CostStartUpH.L(u,z);
UnitShutDownCost(u,z)= CostShutDownH.L(u,z);
UnitRampUpCost(u,z)= CostRampUpH.L(u,z);
UnitRampDownCost(u,z)= CostRampDownH.L(u,z);
UnitVariableCost(u,n,z)$(Location(u,n) EQ 1)= CostVariable(u,z) * PowerN.L(u,n,z)
                                            + (sum(nn$(Location(u,nn) EQ 0),CostVariableB(u,z) * PowerN.L(u,nn,z)))$(not KSA(n))
                                            + (sum(nn$(Location(u,nn) EQ 0 and not KSA(nn)),CostVariableB(u,z) * PowerN.L(u,nn,z)))$( KSA(n))
                                            + (sum(nn$(Location(u,nn) EQ 0 and KSA(nn)),CostVariable(u,z) * PowerN.L(u,nn,z)))$( KSA(n));
UnitOperationCost(u,n,z)$(Location(u,n) EQ 1)= CostFixed(u)*Committed.L(u,z)
                                             + CostStartUpH.L(u,z) + CostShutDownH.L(u,z)
                                             + CostRampUpH.L(u,z) + CostRampDownH.L(u,z)
                                             + CostVariable(u,z) * PowerN.L(u,n,z)
                                             + (sum(nn$(Location(u,nn) EQ 0),CostVariableB(u,z) * PowerN.L(u,nn,z)))$(not KSA(n))
                                             + (sum(nn$(Location(u,nn) EQ 0 and not KSA(nn)),CostVariableB(u,z) * PowerN.L(u,nn,z)))$( KSA(n))
                                             + (sum(nn$(Location(u,nn) EQ 0 and KSA(nn)),CostVariable(u,z) * PowerN.L(u,nn,z)))$( KSA(n));

*Results about local generation, imports, and exports  in each node in the system
LocalOutputPower(n,z)= sum(u$(Location(u,n) EQ 1), PowerN.L(u,n,z));
LocalOutputPowerCost(n,z)= sum(u$(Location(u,n) EQ 1), PowerN.L(u,n,z)*CostVariable(u,z));
KSALocalOutputPower(z)= sum((u,n)$(Location(u,n) EQ 1 and KSA(n)), PowerN.L(u,n,z))
                                        +sum((u,n,nn)$(Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and KSA(nn)), PowerN.L(u,nn,z));
KSALocalOutputPowerCost(z)= sum((u,n)$(Location(u,n) EQ 1 and KSA(n)), PowerN.L(u,n,z)*CostVariable(u,z))
                                        +sum((u,n,nn)$(Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and KSA(nn)), PowerN.L(u,nn,z)*CostVariable(u,z));
**(Total import = import)
**(Net import = import - export)
TotalImportedPower(n,z)= sum(u$(Location(u,n) EQ 0),PowerN.L(u,n,z));
TotalImportedPowerCost(n,z)= (sum(u$(Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariableB(u,z)))$(not KSA(n))
                           + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and KSA(nn)),PowerN.L(u,n,z)*CostVariable(u,z)))$(KSA(n))
                           + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and not KSA(nn)),PowerN.L(u,n,z)*CostVariableB(u,z)))$(KSA(n));
NetImportedPower(n,z)= sum(u$(Location(u,n) EQ 0),PowerN.L(u,n,z)) - sum(u$(Location(u,n) EQ 1),Power.L(u,z)-PowerN.L(u,n,z));
NetImportedPowerCost(n,z)= (sum(u$(Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariableB(u,z)))$(not KSA(n))
                           + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and KSA(nn)),PowerN.L(u,n,z)*CostVariable(u,z)))$(KSA(n))
                           + (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and not KSA(nn)),PowerN.L(u,n,z)*CostVariableB(u,z)))$(KSA(n))
                           - (sum(u$(Location(u,n) EQ 1),(Power.L(u,z)-PowerN.L(u,n,z))*CostVariableB(u,z)))$(not KSA(n))
                           - (sum((u,nn)$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(KSA(n))
                           - (sum((u,nn)$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z)*CostVariable(u,z)))$(KSA(n));
ImportedPowerFromNode(n,nn,z)= sum(u$(Location(u,nn) EQ 1 and Location(u,n) EQ 0),PowerN.L(u,n,z));
ImportedPowerFromNodeCost(n,nn,z)= (sum(u$(Location(u,nn) EQ 1 and Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariableB(u,z)))$(not KSA(n))
                                 + (sum(u$(Location(u,nn) EQ 1 and Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariableB(u,z)))$(KSA(n) and not KSA(nn))
                                 + (sum(u$(Location(u,nn) EQ 1 and Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariable(u,z)))$(KSA(n) and KSA(nn));
NetImportedPowerFromNode(n,nn,z)= sum(u$(Location(u,nn) EQ 1 and Location(u,n) EQ 0),PowerN.L(u,n,z))
                                - sum(u$(Location(u,n) EQ 1 and Location(u,nn) EQ 0),PowerN.L(u,nn,z));
NetImportedPowerFromNodeCost(n,nn,z)= (sum(u$(Location(u,nn) EQ 1 and Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariableB(u,z)))$(not KSA(n))
                                 + (sum(u$(Location(u,nn) EQ 1 and Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariableB(u,z)))$(KSA(n) and not KSA(nn))
                                 + (sum(u$(Location(u,nn) EQ 1 and Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariable(u,z)))$(KSA(n) and KSA(nn))
                                 - (sum(u$(Location(u,n) EQ 1 and Location(u,nn) EQ 0),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(not KSA(n))
                                 - (sum(u$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(KSA(n))
                                 - (sum(u$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z)*CostVariable(u,z)))$(KSA(n));
KSATotalImportedPower(z)= sum((u,n,nn)$(Location(u,n) EQ 0 and KSA(n) and Location(u,nn) EQ 1 and not KSA(nn)), PowerN.L(u,n,z));
KSATotalImportedPowerCost(z)= sum((u,n,nn)$(Location(u,n) EQ 0 and KSA(n) and Location(u,nn) EQ 1 and not KSA(nn)), PowerN.L(u,n,z)*CostVariableB(u,z));
KSANetImportedPower(z)= sum((u,n,nn)$(Location(u,n) EQ 0 and KSA(n) and Location(u,nn) EQ 1 and not KSA(nn)), PowerN.L(u,n,z))
                      - sum((u,n,nn)$(Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z));
KSANetImportedPowerCost(z)= sum((u,n,nn)$(Location(u,n) EQ 0 and KSA(n) and Location(u,nn) EQ 1 and not KSA(nn)), PowerN.L(u,n,z)*CostVariableB(u,z))
                          - sum((u,n,nn)$(Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z));
KSAImportedPowerFromNode(n,z)= sum((u,nn)$(Location(u,n) EQ 1 and not KSA(n) and Location(u,nn) EQ 0 and KSA(nn) ),PowerN.L(u,nn,z));
KSAImportedPowerFromNodeCost(n,z)= sum((u,nn)$(Location(u,n) EQ 1 and not KSA(n) and Location(u,nn) EQ 0 and KSA(nn) ),PowerN.L(u,nn,z)*CostVariableB(u,z));
KSANetImportedPowerFromNode(n,z)= sum((u,nn)$(Location(u,n) EQ 1 and not KSA(n) and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z))
                                - sum((u,nn)$(Location(u,nn) EQ 1 and KSA(nn) and Location(u,n) EQ 0 and not KSA(n)),PowerN.L(u,n,z));
KSANetImportedPowerFromNodeCost(n,z)= sum((u,nn)$(Location(u,n) EQ 1 and not KSA(n) and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z))
                                - sum((u,nn)$(Location(u,nn) EQ 1 and KSA(nn) and Location(u,n) EQ 0 and not KSA(n)),PowerN.L(u,n,z)*CostVariableB(u,z));
**(Total export = export)
**(Net export = export - import)
TotalExportedPower(n,z)= sum(u$(Location(u,n) EQ 1),Power.L(u,z)-PowerN.L(u,n,z));
TotalExportedPowerCost(n,z)= (sum(u$(Location(u,n) EQ 1),(Power.L(u,z)-PowerN.L(u,n,z))*CostVariableB(u,z)))$(not KSA(n))
                           + (sum((u,nn)$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(KSA(n))
                           + (sum((u,nn)$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z)*CostVariable(u,z)))$(KSA(n));
NetExportedPower(n,z) = sum(u$(Location(u,n) EQ 1),Power.L(u,z)-PowerN.L(u,n,z)) - sum(u$(Location(u,n) EQ 0),PowerN.L(u,n,z));
NetExportedPowerCost(n,z) = (sum(u$(Location(u,n) EQ 1),(Power.L(u,z)-PowerN.L(u,n,z))*CostVariableB(u,z)))$(not KSA(n))
                           + (sum((u,nn)$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(KSA(n))
                           + (sum((u,nn)$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z)*CostVariable(u,z)))$(KSA(n))
                           - (sum(u$(Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariableB(u,z)))$(not KSA(n))
                           - (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and KSA(nn)),PowerN.L(u,n,z)*CostVariable(u,z)))$(KSA(n))
                           - (sum((u,nn)$(Location(u,n) EQ 0 and Location(u,nn) EQ 1 and not KSA(nn)),PowerN.L(u,n,z)*CostVariableB(u,z)))$(KSA(n));
ExportedPowerToNode(n,nn,z)= sum(u$(Location(u,n) EQ 1 and Location(u,nn) EQ 0),PowerN.L(u,nn,z));
ExportedPowerToNodeCost(n,nn,z)= (sum(u$(Location(u,n) EQ 1 and Location(u,nn) EQ 0),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(not KSA(n))
                               + (sum(u$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(KSA(n))
                               + (sum(u$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z)*CostVariable(u,z)))$(KSA(n));
NetExportedPowerToNode(n,nn,z)= sum(u$(Location(u,n) EQ 1 and Location(u,nn) EQ 0),PowerN.L(u,nn,z))
                              - sum(u$(Location(u,nn) EQ 1 and Location(u,n) EQ 0),PowerN.L(u,n,z));
NetExportedPowerToNodeCost(n,nn,z)= (sum(u$(Location(u,n) EQ 1 and Location(u,nn) EQ 0),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(not KSA(n))
                               + (sum(u$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(KSA(n))
                               + (sum(u$(Location(u,n) EQ 1 and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z)*CostVariable(u,z)))$(KSA(n))
                               - (sum(u$(Location(u,nn) EQ 1 and Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariableB(u,z)))$(not KSA(n))
                               - (sum(u$(Location(u,nn) EQ 1 and Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariableB(u,z)))$(KSA(n) and not KSA(nn))
                               - (sum(u$(Location(u,nn) EQ 1 and Location(u,n) EQ 0),PowerN.L(u,n,z)*CostVariable(u,z)))$(KSA(n) and KSA(nn));
KSATotalExportedPower(z)= sum((u,n,nn)$(Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z));
KSATotalExportedPowerCost(z)= sum((u,n,nn)$(Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z));
KSANetExportedPower(z)= sum((u,n,nn)$(Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z))
                      - sum((u,n,nn)$(Location(u,n) EQ 0 and KSA(n) and Location(u,nn) EQ 1 and not KSA(nn)), PowerN.L(u,n,z));
KSANetExportedPowerCost(z)= sum((u,n,nn)$(Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z))
                          - sum((u,n,nn)$(Location(u,n) EQ 0 and KSA(n) and Location(u,nn) EQ 1 and not KSA(nn)), PowerN.L(u,n,z)*CostVariableB(u,z));
KSAExportedPowerToNode(n,z)= sum((u,nn)$(Location(u,nn) EQ 1 and KSA(nn) and Location(u,n) EQ 0 and not KSA(n)),PowerN.L(u,n,z));
KSAExportedPowerToNodeCost(n,z)= sum((u,nn)$(Location(u,nn) EQ 1 and KSA(nn) and Location(u,n) EQ 0 and not KSA(n)),PowerN.L(u,n,z)*CostVariableB(u,z));
KSANetExportedPowerToNode(n,z)= sum((u,nn)$(Location(u,nn) EQ 1 and KSA(nn) and Location(u,n) EQ 0 and not KSA(n)),PowerN.L(u,n,z))
                              - sum((u,nn)$(Location(u,n) EQ 1 and not KSA(n) and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z));
KSANetExportedPowerToNodeCost(n,z)= sum((u,nn)$(Location(u,nn) EQ 1 and KSA(nn) and Location(u,n) EQ 0 and not KSA(n)),PowerN.L(u,n,z)*CostVariableB(u,z))
                                                            - sum((u,nn)$(Location(u,n) EQ 1 and not KSA(n) and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z));

*Results about each fuel for each node in the system (consumption of fuel as well as fuel power)
*Note: fuel consumption is the amount of fuel after taking into account unit's efficiency. Fuel power is the amount of power corresponding to that fuel.
NodeFuelPower(n,f,z)=sum(u$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1),Power.L(u,z));
NodeFuelPowerCost(n,f,z)=sum(u$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1),PowerN.L(u,n,z)*CostVariable(u,z))
                        + (sum((u,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and Location(u,nn) EQ 0),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(not KSA(n))
                        + (sum((u,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(KSA(n))
                        + (sum((u,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z)*CostVariable(u,z)))$(KSA(n));
NodeFuelConsumption(n,f,z)=sum(u$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1),Power.L(u,z)/Efficiency(u));
NodeFuelCost(n,f,z)=sum(u$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1), (Power.L(u,z)/Efficiency(u))*FuelPricePerZone(n,f,"International"));
NodeFuelGovSpending(n,f,z)=sum(u$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1), (Power.L(u,z)/Efficiency(u))*(FuelPricePerZone("SA_EOA",f,"International")-FuelPricePerZone(n,f,"Subsidized")));
KSAFuelPower(f,z)=sum(n$(KSA(n)),sum(u$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1),Power.L(u,z)));
KSAFuelPowerCost(f,z)=sum((u,n)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and KSA(n)),PowerN.L(u,n,z)*CostVariable(u,z))
                                    + sum((u,n,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z)*CostVariable(u,z))
                                    + sum((u,n,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z));
KSAFuelConsumption(f,z)=sum(n$(KSA(n)),sum(u$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1),Power.L(u,z)/Efficiency(u)));
KSAFuelCost(f,z)=sum(n$(KSA(n)),sum(u$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1), (Power.L(u,z)/Efficiency(u))*FuelPricePerZone("SA_EOA",f,"International")));
KSAFuelGovSpending(f,z)=sum(n$(KSA(n)),sum(u$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1), (Power.L(u,z)/Efficiency(u))*(FuelPricePerZone("SA_EOA",f,"International")-FuelPricePerZone("SA_EOA",f,"Subsidized"))));

*Results about local generation, imports, and exports for each fuel and each node in the system
*Note: the parameters "NodeFuelImportCost" & "NodeFuelExportCost" are defined to calculate the cost of fuel using the actual fuel price (without subsidy)
NodeLocalFuelPowerCost(n,f,z)=sum(u$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1),PowerN.L(u,n,z)*CostVariable(u,z));

NodeFuelPowerExport(n,f,z)=sum((u,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and Location(u,nn) EQ 0),PowerN.L(u,nn,z));
NodeFuelPowerExportCost(n,f,z)= (sum((u,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and Location(u,nn) EQ 0),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(not KSA(n))
                              + (sum((u,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z)))$(KSA(n))
                              + (sum((u,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z)*CostVariable(u,z)))$(KSA(n));
NodeFuelExport(n,f,z)=sum((u,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and Location(u,nn) EQ 0),PowerN.L(u,nn,z)/Efficiency(u));
NodeFuelExportCost(n,f,z)=sum((u,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and Location(u,nn) EQ 0),(PowerN.L(u,nn,z)/Efficiency(u))*FuelPricePerZone(n,f,"International"));

NodeFuelPowerImport(n,f,z)=sum(u$(Fuel(u,f) EQ 1 and Location(u,n) EQ 0 ),PowerN.L(u,n,z));
NodeFuelPowerImportCost(n,f,z)= (sum(u$(Fuel(u,f) EQ 1 and Location(u,n) EQ 0 ),PowerN.L(u,n,z)*CostVariableB(u,z)))$(not KSA(n))
                              + (sum((u,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 0 and Location(u,nn) EQ 1 and not KSA(nn)),PowerN.L(u,n,z)*CostVariableB(u,z)))$(KSA(n))
                              + (sum((u,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 0 and Location(u,nn) EQ 1 and KSA(nn)),PowerN.L(u,n,z)*CostVariable(u,z)))$(KSA(n));
NodeFuelImport(n,f,z)=sum(u$(Fuel(u,f) EQ 1 and Location(u,n) EQ 0),PowerN.L(u,n,z)/Efficiency(u));
NodeFuelImportCost(n,f,z)=sum((u,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 0 and Location(u,nn) EQ 1),(PowerN.L(u,n,z)/Efficiency(u))*FuelPricePerZone(nn,f,"International"));

KSALocalFuelPowerCost(f,z)=sum((u,n)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and KSA(n)),PowerN.L(u,n,z)*CostVariable(u,z))
                                            + sum((u,n,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and KSA(nn)),PowerN.L(u,nn,z)*CostVariable(u,z));

KSAFuelPowerExport(f,z)=sum((u,n,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z));
KSAFuelPowerExportCost(f,z)=sum((u,n,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)*CostVariableB(u,z));
KSAFuelExport(f,z)=sum((u,n,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and not KSA(nn)),PowerN.L(u,nn,z)/Efficiency(u));
KSAFuelExportCost(f,z)=sum((u,n,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1 and KSA(n) and Location(u,nn) EQ 0 and not KSA(nn)),(PowerN.L(u,nn,z)/Efficiency(u))*FuelPricePerZone(n,f,"International"));

KSAFuelPowerImport(f,z)=sum((u,n,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 0 and KSA(n) and Location(u,nn) EQ 1 and not KSA(nn)),PowerN.L(u,n,z));
KSAFuelPowerImportCost(f,z)=sum((u,n,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 0 and KSA(n) and Location(u,nn) EQ 1 and not KSA(nn)),PowerN.L(u,n,z)*CostVariableB(u,z));
KSAFuelImport(f,z)=sum((u,n,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 0 and KSA(n) and Location(u,nn) EQ 1 and not KSA(nn)),PowerN.L(u,n,z)/Efficiency(u));
KSAFuelImportCost(f,z)=sum((u,n,nn)$(Fuel(u,f) EQ 1 and Location(u,n) EQ 0 and KSA(n) and Location(u,nn) EQ 1 and not KSA(nn)),(PowerN.L(u,n,z)/Efficiency(u))*FuelPricePerZone(n,f,"International"));

EXECUTE_UNLOAD "Results.gdx"
UnitCommitment,
PowerFlow,
TotalNodeOperationCost,
TotalNodeVariableCost,
TotalKSAVariableCost,
NetNodeVariableCost,
NetKSAVariableCost,
ElectricityNodePrice,
ElectricityNodePrice2,
ElectricityNodePrice3,
ElectricityKSAPrice,
ElectricityKSAPrice2,
ElectricityKSAPrice3,
NodeOutputShedLoad,
NodeOutputCurtailedPower,
NodeShadowPrice,
TotalNodeDemand,
TotalKSADemand,
LostLoad_MaxPower,
LostLoad_MinPower,
LostLoad_2D,
LostLoad_2U,
LostLoad_3U,
LostLoad_RampUp,
LostLoad_RampDown,
status,
PowerFlowMaxLimit,
PowerFlowMinLimit,
UnitOutputPower,
UnitOutputPowerInside,
UnitOutputPowerOutside,
UnitOutputPowerForNode,
UnitFixedCost,
UnitStartUpCost,
UnitShutDownCost,
UnitRampUpCost,
UnitRampDownCost,
UnitVariableCost,
UnitOperationCost,
LocalOutputPower,
LocalOutputPowerCost,
KSALocalOutputPower,
KSALocalOutputPowerCost,
TotalImportedPower,
TotalImportedPowerCost,
NetImportedPower,
NetImportedPowerCost,
ImportedPowerFromNode,
ImportedPowerFromNodeCost,
NetImportedPowerFromNode,
NetImportedPowerFromNodeCost,
KSATotalImportedPower,
KSATotalImportedPowerCost,
KSANetImportedPower,
KSANetImportedPowerCost,
KSAImportedPowerFromNode,
KSAImportedPowerFromNodeCost,
KSANetImportedPowerFromNode,
KSANetImportedPowerFromNodeCost,
TotalExportedPower,
TotalExportedPowerCost,
NetExportedPower,
NetExportedPowerCost,
ExportedPowerToNode,
ExportedPowerToNodeCost,
NetExportedPowerToNode,
NetExportedPowerToNodeCost,
KSATotalExportedPower,
KSATotalExportedPowerCost,
KSANetExportedPower,
KSANetExportedPowerCost,
KSAExportedPowerToNode,
KSAExportedPowerToNodeCost,
KSANetExportedPowerToNode,
KSANetExportedPowerToNodeCost,
LineCongestion,
LineCongestion_KSA_GCC,
LineCongestion_KW_GCC,
LineCongestion_BA_GCC,
LineCongestion_QA_GCC,
LineCongestion_UAE_GCC,
LineCongestion_OM_GCC,
LineCongestion_UAE_Salwa,
LineCongestion_Ghunan_Salwa,
LineCongestion_Ghunan_Alfadhili,
TotalSystemCost,
NodeFuelPower,
NodeFuelPowerCost,
KSAFuelPowerCost,
KSAFuelPower,
NodeFuelConsumption,
KSAFuelConsumption,
NodeFuelCost,
KSAFuelCost,
NodeFuelGovSpending,
KSAFuelGovSpending,
NodeLocalFuelPowerCost,
KSALocalFuelPowerCost,
NodeFuelPowerExport,
NodeFuelPowerExportCost,
NodeFuelExport,
NodeFuelExportCost,
NodeFuelPowerImport,
NodeFuelPowerImportCost,
NodeFuelImport,
NodeFuelImportCost,
KSAFuelPowerExport,
KSAFuelPowerExportCost,
KSAFuelExport,
KSAFuelExportCost,
KSAFuelPowerImport,
KSAFuelPowerImportCost,
KSAFuelImport,
KSAFuelImportCost
;

$onorder
* Exit here if the PrintResult option is set to 0:
$if not %PrintResults%==1 $exit

EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=N par=Technology rng=Technology!A1 rdim=2 cdim=0'
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=N par=PowerCapacity rng=PowerCapacity!A1 rdim=1 cdim=0'
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=N par=PowerInitial rng=PowerInitialA1 rdim=1 cdim=0'
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=N par=RampDownMaximum rng=RampDownMaximum!A1 rdim=1 cdim=0'
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=N par=RampShutDownMaximum rng=RampShutDownMaximum!A1 rdim=1 cdim=0'
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=N par=RampStartUpMaximum rng=RampStartUpMaximum!A1 rdim=1 cdim=0'
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=N par=RampUpMaximum rng=RampUpMaximum!A1 rdim=1 cdim=0'
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=N par=TimeUpMinimum rng=TimeUpMinimum!A1 rdim=1 cdim=0'
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=N par=TimeDownMinimum rng=TimeDownMinimum!A1 rdim=1 cdim=0'
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=N par=Reserve rng=Reserve!A1 rdim=1 cdim=0'
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=N par=LoadShedding rng=LoadShedding!A1 rdim=1 cdim=0'
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=N par=FlowMaximum rng=FlowMaximum!A1 rdim=1 cdim=1'
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=N par=AvailabilityFactor rng=AvailabilityFactor!A1 rdim=1 cdim=1'
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=Y par=OutageFactor rng=OutageFactor!A1 rdim=1 cdim=1'
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=N par=Demand rng=Demand!A1 rdim=2 cdim=1'
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=N par=PartLoadMin rng=PartLoadMin!A1 rdim=1 cdim=0'

EXECUTE 'GDXXRW.EXE "Results.gdx" O="Results.xlsx" Squeeze=N var=CurtailedPower rng=CurtailedPower!A1 rdim=1 cdim=1'
EXECUTE 'GDXXRW.EXE "Results.gdx" O="Results.xlsx" Squeeze=N var=ShedLoad rng=ShedLoad!A1 rdim=1 cdim=1'
EXECUTE 'GDXXRW.EXE "Results.gdx" O="Results.xlsx" Squeeze=N par=OutputCommitted rng=Committed!A1 rdim=1 cdim=1'
EXECUTE 'GDXXRW.EXE "Results.gdx" O="Results.xlsx" Squeeze=N par=OutputFlow rng=Flow!A1 rdim=1 cdim=1'
EXECUTE 'GDXXRW.EXE "Results.gdx" O="Results.xlsx" Squeeze=N par=OutputPower rng=Power!A5 epsout=0 rdim=1 cdim=1'
EXECUTE 'GDXXRW.EXE "Results.gdx" O="Results.xlsx" Squeeze=N par=OutputStorageInput rng=StorageInput!A1 rdim=1 cdim=1'
EXECUTE 'GDXXRW.EXE "Results.gdx" O="Results.xlsx" Squeeze=N par=OutputStorageLevel rng=StorageLevel!A1 rdim=1 cdim=1'
EXECUTE 'GDXXRW.EXE "Results.gdx" O="Results.xlsx" Squeeze=N par=OutputSystemCost rng=SystemCost!A1 rdim=1 cdim=0'
EXECUTE 'GDXXRW.EXE "Results.gdx" O="Results.xlsx" Squeeze=Y var=LostLoad_MaxPower rng=LostLoad_MaxPower!A1 rdim=1 cdim=1'
EXECUTE 'GDXXRW.EXE "Results.gdx" O="Results.xlsx" Squeeze=Y var=LostLoad_MinPower rng=LostLoad_MinPower!A1 rdim=1 cdim=1'
EXECUTE 'GDXXRW.EXE "Results.gdx" O="Results.xlsx" Squeeze=Y var=LostLoad_2D rng=LostLoad_2D!A1 rdim=1 cdim=1'
EXECUTE 'GDXXRW.EXE "Results.gdx" O="Results.xlsx" Squeeze=Y var=LostLoad_2U rng=LostLoad_2U!A1 rdim=1 cdim=1'
EXECUTE 'GDXXRW.EXE "Results.gdx" O="Results.xlsx" Squeeze=Y var=LostLoad_RampUp rng=LostLoad_RampUp!A1 rdim=1 cdim=1'
EXECUTE 'GDXXRW.EXE "Results.gdx" O="Results.xlsx" Squeeze=Y var=LostLoad_RampDown rng=LostLoad_RampDown!A1 rdim=1 cdim=1'

$exit

$Label DebugSection

$gdxin debug.gdx
$LOAD day
$LOAD PowerInitial_dbg
$LOAD CommittedInitial_dbg
;
PowerInitial(u) = PowerInitial_dbg(u); CommittedInitial(u) = CommittedInitial_dbg(u);
FirstHour = (day-1)*24+1;
LastHour = min(card(h),FirstHour + (Config("RollingHorizon Length","day")+Config("RollingHorizon LookAhead","day")) * 24 - 1);
LastKeptHour = LastHour - Config("RollingHorizon LookAhead","day") * 24;
i(h) = no;
i(h)$(ord(h)>=firsthour and ord(h)<=lasthour)=yes;
$If %Verbose% == 1   Display TimeUpLeft_initial,TimeUpLeft_JustStarted,PowerInitial,CommittedInitial;
$If %LPFormulation% == 1          SOLVE UCM_SIMPLE USING LP MINIMIZING SystemCostD;
$If not %LPFormulation% == 1      SOLVE UCM_SIMPLE USING MIP MINIMIZING SystemCostD;
$If %LPFormulation% == 1          Display EQ_Objective_function.M, EQ_CostRampUp.M, EQ_CostRampDown.M, EQ_Demand_balance_DA.M, EQ_Power_available.M, EQ_Ramp_up.M, EQ_Ramp_down.M, EQ_Flow_limits_lower.M ;
$If not %LPFormulation% == 1      Display EQ_Objective_function.M, EQ_CostStartUp.M, EQ_CostShutDown.M, EQ_Demand_balance_DA.M, EQ_Power_must_run.M, EQ_Power_available.M, EQ_Ramp_up.M, EQ_Ramp_down.M, EQ_MaxShutDowns.M, EQ_MaxShutDowns_JustStarted.M, EQ_MaxStartUps.M, EQ_MaxStartUps_JustStopped.M, EQ_Flow_limits_lower.M ;

display day,FirstHour,LastHour,LastKeptHour;
Display PowerInitial,CommittedInitial;
Display Flow.L,Power.L,Committed.L,ShedLoad.L,StorageLevel.L,StorageInput.L,SystemCost.L,Spillage.L,StorageLevel.L,StorageInput.L,LL_MaxPower.L,LL_MinPower.L,LL_2U.L,LL_2D.L,LL_RampUp.L,LL_RampDown.L;
