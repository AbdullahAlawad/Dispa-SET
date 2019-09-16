$Title UCM model

$eolcom //
Option threads=8;
Option IterLim=1000000000;
Option ResLim = 10000000000;
*Option optca=0.0;


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
l                Lines
u                Units
t                Generation technologies
tr(t)            Renewable generation technologies
f                Fuel types
p                Pollutants
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
* \u indicate that the value is provided for one single unit
PARAMETERS
AvailabilityFactor(u,h)          [%]      Availability factor
CommittedInitial(u)              [n.a.]   Initial committment status
Config
*CostCurtailment(n,h)             [$\MW]  Curtailment costs
CostFixed(u)                     [$\h]    Fixed costs
CostRampUp(u)                    [$\MW\h] Ramp-up costs
CostRampDown(u)                  [$\MW\h] Ramp-down costs
CostShutDown(u)                  [$\u]    Shut-down costs
CostStartUp(u)                   [$\u]    Start-up costs
CostVariable(u,h)                [$\MW]   Variable costs
CostLoadShedding(n,h)            [$\MWh] Cost of load shedding
Curtailment(n)                   [n.a]    Curtailment allowed or not {1 0} at node n
Demand(mk,n,h)                   [MW]     Demand
Efficiency(u)                    [%]      Efficiency
EmissionMaximum(n,p)             [tP]     Emission limit
EmissionRate(u,p)                [tP\MWh] P emission rate
FlowMaximum(l,h)                 [MW]     Line limits
FlowMinimum(l,h)                 [MW]     Minimum flow
Fuel(u,f)                        [n.a.]   Fuel type {1 0}
FuelPricePerZone       *[$\MWh]  Average international & subsidized prices for each fuel in each zone
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
RampStartUpMaximumH(u,h)       [MW\h\u]   Start-up ramp limit - Clustered formulation
RampShutDownMaximumH(u,h)      [MW\h\u]   Shut-down ramp limit - Clustered formulation
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
PowerMustRun(u,h)                [MW\u]    Minimum power output
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
$LOAD l
$LOAD u
$LOAD t
$LOAD tr
$LOAD f
$LOAD p
$LOAD h
$LOAD z
$LOAD AvailabilityFactor
$LOAD Config
$LOAD CostFixed
$LOAD CostLoadShedding
$LOAD CostShutDown
$LOAD CostStartUp
$LOAD CostVariable
$LOAD Curtailment
$LOAD Demand
$LOAD Efficiency
$LOAD EmissionMaximum
$LOAD EmissionRate
$LOAD FlowMaximum
$LOAD FlowMinimum
$LOAD Fuel
$LOAD FuelPricePerZone
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
l,
u,
t,
tr,
f,
p,
s,
h,
AvailabilityFactor,
Config,
CostFixed,
CostShutDown,
CostStartUp,
CostRampUp,
CostVariable,
Demand,
Efficiency,
EmissionMaximum,
EmissionRate,
FlowMaximum,
FlowMinimum,
Fuel,
LineNode,
Location,
LoadShedding
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
TimeUpMinimum
$If %RetrieveStatus% == 1 , CommittedCalc
;

$label skipdisplay

*===============================================================================
*Definition of variables
*===============================================================================
VARIABLES
Committed(u,h)             [n.a.]  Unit committed at hour h {1 0} or integer
StartUp(u,h)        [n.a.]  Unit start up at hour h {1 0}  or integer
ShutDown(u,h)       [n.a.]  Unit shut down at hour h {1 0} or integer
;

$If %LPFormulation% == 1 POSITIVE VARIABLES Committed (u,h) ; Committed.UP(u,h) = 1 ;
$If not %LPFormulation% == 1 INTEGER VARIABLES Committed (u,h), StartUp(u,h), ShutDown(u,h) ; Committed.UP(u,h) = Nunits(u) ; StartUp.UP(u,h) = Nunits(u) ; ShutDown.UP(u,h) = Nunits(u) ;

POSITIVE VARIABLES
CostStartUpH(u,h)          [$]   Cost of starting up
CostShutDownH(u,h)         [$]   cost of shutting down
CostRampUpH(u,h)           [$]   Ramping cost
CostRampDownH(u,h)         [$]   Ramping cost
CurtailedPower(n,h)        [MW]    Curtailed power at node n
Flow(l,h)                  [MW]    Flow through lines
Power(u,h)                 [MW]    Power output
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
SystemCost(n,h)              [$]   Hourly system cost
Reserve_2U(u,h)            [MW]    Spinning reserve up
Reserve_2D(u,h)            [MW]    Spinning reserve down
Reserve_3U(u,h)            [MW]    Non spinning quick start reserve up
;

free variable
SystemCostD                ![$]   Total system cost for one optimization period
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

$If %Verbose% == 1 Display RampStartUpMaximum, RampShutDownMaximum, CommittedInitial;

$offorder

*===============================================================================
*Declaration and definition of equations
*===============================================================================
EQUATIONS
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

*Objective function

$ifthen [%LPFormulation% == 1]
EQ_SystemCost(n,i)..
         SystemCost(n,i)
         =E=
         sum(u$(Location(u,n) EQ 1),CostFixed(u)*Committed(u,i))
         +sum(u$(Location(u,n) EQ 1),CostRampUpH(u,i) + CostRampDownH(u,i))
         +sum(u$(Location(u,n) EQ 1),CostVariable(u,i) * Power(u,i))
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
         +sum(u$(Location(u,n) EQ 1),CostVariable(u,i) * Power(u,i))
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
         sum((n,i),SystemCost(n,i)) + sum((l,i),PriceTransmission(l,i)*Flow(l,i))
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

*Hourly demand balance in the day-ahead market for each node
EQ_Demand_balance_DA(n,i)..
         sum(u,Power(u,i)*Location(u,n))
          +sum(l,Flow(l,i)*LineNode(l,n))
         =E=
         Demand("DA",n,i)
         -ShedLoad(n,i)
         -LL_MaxPower(n,i)
         +LL_MinPower(n,i)
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

*Force Unit commitment/decommitment:
* E.g: renewable units with AF>0 must be committed
EQ_Force_Commitment(u,i)$((sum(tr,Technology(u,tr))>=1 and LoadMaximum(u,i)>0))..
         Committed(u,i)
         =G=
         1;

* E.g: renewable units with AF=0 must be decommitted
EQ_Force_DeCommitment(u,i)$(LoadMaximum(u,i)=0)..
         Committed(u,i)
         =E=
         0;

*Load shedding
EQ_LoadShedding(n,i)..
         ShedLoad(n,i)
         =L=
         LoadShedding(n,i)
;

* Minimum level at the end of the optimization horizon:
*EQ_Heat_Storage_boundaries(chp,i)$(ord(i) = card(i))..
*         StorageFinalMin(chp)
*         =L=
*         StorageLevel(chp,i)
*;
*===============================================================================
*Definition of models
*===============================================================================
MODEL UCM_SIMPLE /
EQ_Objective_function,
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
EQ_SystemCost
*EQ_Emission_limits,
EQ_Flow_limits_lower,
EQ_Flow_limits_upper,
EQ_Force_Commitment,
EQ_Force_DeCommitment,
EQ_LoadShedding,
$If %RetrieveStatus% == 1 EQ_CommittedCalc
/
;
UCM_SIMPLE.optcr = 0.01;
UCM_SIMPLE.optfile=1;

*===============================================================================
*Solving loop
*===============================================================================

ndays = floor(card(h)/24);
if (Config("RollingHorizon LookAhead","day") > ndays -1, abort "The look ahead period is longer than the simulation length";);

* Some parameters used for debugging:
failed=0;
parameter CommittedInitial_dbg(u), PowerInitial_dbg(u);

* Fixing the initial guesses:
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
NodeOutputShedLoad(n,h)
NodeShadowPrice(n,h)
TotalNodeDemand(n,h)

PowerFlowMaxLimit(l,h)
PowerFlowMinLimit(l,h)

UnitOutputPower(u,h)
UnitFixedCost(u,h)
UnitStartUpCost(u,h)
UnitShutDownCost(u,h)
UnitRampUpCost(u,h)
UnitRampDownCost(u,h)

LineCongestion(l,h)

TotalSystemCost(h)
NodeFuelPower(n,f,h)
NodeFuelConsumption(n,f,h)
NodeFuelCost(n,f,h)
NodeFuelGovSpending(n,f,h)
;
*Results about the entire system
TotalSystemCost(z)=sum(n,SystemCost.L(n,z));
UnitCommitment(u,z)=Committed.L(u,z);
PowerFlow(l,z)=Flow.L(l,z);
LineCongestion(l,z)= 1 $(EQ_Flow_limits_upper.m(l,z) NE 0);
NodeShadowPrice(n,z) = EQ_Demand_balance_DA.m(n,z);

*Results about each node in the system
TotalNodeOperationCost(n,z)=SystemCost.L(n,z);
NodeOutputShedLoad(n,z) = ShedLoad.L(n,z);
NodeOutputCurtailedPower(n,z)= CurtailedPower.L(n,z);
TotalNodeDemand(n,z) = Demand("DA",n,z);
LostLoad_MaxPower(n,z)  = LL_MaxPower.L(n,z);
LostLoad_MinPower(n,z)  = LL_MinPower.L(n,z);
LostLoad_2D(n,z) = LL_2D.L(n,z);
LostLoad_2U(n,z) = LL_2U.L(n,z);
LostLoad_3U(n,z) = LL_3U.L(n,z);
LostLoad_RampUp(n,z)    = sum(u,LL_RampUp.L(u,z)*Location(u,n));
LostLoad_RampDown(n,z)  = sum(u,LL_RampDown.L(u,z)*Location(u,n));


*Results about dual variables of line limits constraint
PowerFlowMaxLimit(l,z)= EQ_Flow_limits_upper.m(l,z);
PowerFlowMinLimit(l,z)= EQ_Flow_limits_lower.m(l,z);

*Results about each power unit in the system
UnitOutputPower(u,z)=Power.L(u,z);
UnitFixedCost(u,z)= CostFixed(u)*Committed.L(u,z);
UnitStartUpCost(u,z)= CostStartUpH.L(u,z);
UnitShutDownCost(u,z)= CostShutDownH.L(u,z);
UnitRampUpCost(u,z)= CostRampUpH.L(u,z);
UnitRampDownCost(u,z)= CostRampDownH.L(u,z);

*Results about each fuel for each node in the system (consumption of fuel as well as fuel power)
*Note: fuel consumption is the amount of fuel after taking into account unit's efficiency. Fuel power is the amount of power corresponding to that fuel.
NodeFuelPower(n,f,z)=sum(u$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1),Power.L(u,z));
NodeFuelConsumption(n,f,z)=sum(u$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1),Power.L(u,z)/Efficiency(u));
NodeFuelCost(n,f,z)=sum(u$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1), (Power.L(u,z)/Efficiency(u))*FuelPricePerZone(n,f,"International"));
NodeFuelGovSpending(n,f,z)=sum(u$(Fuel(u,f) EQ 1 and Location(u,n) EQ 1), (Power.L(u,z)/Efficiency(u))*(FuelPricePerZone("SA_EOA",f,"International")-FuelPricePerZone(n,f,"Subsidized")));


EXECUTE_UNLOAD "Results.gdx"
UnitCommitment,
PowerFlow,
TotalNodeOperationCost,
NodeOutputShedLoad,
NodeOutputCurtailedPower,
NodeShadowPrice,
TotalNodeDemand,
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
UnitFixedCost,
UnitStartUpCost,
UnitShutDownCost,
UnitRampUpCost,
UnitRampDownCost,
LineCongestion,
TotalSystemCost,
NodeFuelPower,
NodeFuelConsumption,
NodeFuelCost,
NodeFuelGovSpending
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
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=N par=StorageCapacity rng=StorageCapacity!A1 rdim=1 cdim=0'
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=Y par=StorageInflow rng=StorageInflow!A1 rdim=1 cdim=1'
EXECUTE 'GDXXRW.EXE "%inputfilename%" O="Results.xlsx" Squeeze=N par=StorageCapacity rng=StorageCapacity!A1 rdim=1 cdim=0'
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
Display Flow.L,Power.L,Committed.L,ShedLoad.L,SystemCost.L,Spillage.L,LL_MaxPower.L,LL_MinPower.L,LL_2U.L,LL_2D.L,LL_RampUp.L,LL_RampDown.L;
