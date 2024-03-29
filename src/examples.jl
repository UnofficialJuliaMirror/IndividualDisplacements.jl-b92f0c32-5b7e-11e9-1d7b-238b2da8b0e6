
#using Revise, IndividualDisplacements
#include(joinpath(dirname(pathof(IndividualDisplacements)),"examples.jl"))

using MeshArrays, DifferentialEquations, Plots

"""
    ex_1()

Global ocean case -- just reading from file for now.

```
df=IndividualDisplacements.ex_1()

p=dirname(pathof(IndividualDisplacements))
include(joinpath(p,"PlotIndDisp.jl"))
PyPlot.figure(); PlotMapProj(df,300); gcf()
```
"""
function ex_1()
   dirIn="run_offflt/"
   prec=Float32
   df=IndividualDisplacements.ReadDisplacements(dirIn,prec)
end

"""
    ex_2()

Reproducing `MITgcm/verification/flt_example/` case. This is based on an
extended and modified configuration of the standard MITgcm test case.

```
(df,pl)=IndividualDisplacements.ex_2(); display(pl)

p=dirname(pathof(IndividualDisplacements))
include(joinpath(p,"PlotIndDisp.jl"))
PyPlot.figure(); PlotBasic(df,300,100000.0); gcf()
```
"""
function ex_2()
   dirIn="flt_example/"
   prec=Float32
   df=IndividualDisplacements.ReadDisplacements(dirIn,prec)
   uvetc=IndividualDisplacements.ReadGriddedFields()
   #
   tmp=df[df.ID .== 200, :]
   nSteps=Int32(tmp[end,:time]/3600)-2
   ref=transpose([tmp[1:nSteps,:lon] tmp[1:nSteps,:lat]])
   maxLon=80*5.e3
   maxLat=42*5.e3
   for i=1:nSteps-1
       ref[1,i+1]-ref[1,i]>maxLon/2 ? ref[1,i+1:end]-=fill(maxLon,(nSteps-i)) : nothing
       ref[1,i+1]-ref[1,i]<-maxLon/2 ? ref[1,i+1:end]+=fill(maxLon,(nSteps-i)) : nothing
       ref[2,i+1]-ref[2,i]>maxLat/2 ? ref[2,i+1:end]-=fill(maxLat,(nSteps-i)) : nothing
       ref[2,i+1]-ref[2,i]<-maxLat/2 ? ref[2,i+1:end]+=fill(maxLat,(nSteps-i)) : nothing
   end
   ref=ref./uvetc["dx"]
   #
   comp_vel=IndividualDisplacements.VelComp
   get_vel=IndividualDisplacements.VelCopy
   uInit=[tmp[1,:lon];tmp[1,:lat]]./uvetc["dx"]
   du=fill(0.0,2)
   #
   tspan = (0.0,nSteps*3600.0)
   #prob = ODEProblem(get_vel,uInit,tspan,tmp)
   prob = ODEProblem(comp_vel,uInit,tspan,uvetc)
   sol = solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
   #
   Plots.plot(sol[1,:],sol[2,:],linewidth=5,lc=:black, title="One Trajectory Example",
   xaxis="x",yaxis="y",label="Julia Solution") # legend=false
   pl=Plots.plot!(ref[1,:],ref[2,:],lw=3,ls=:dash,lc=:red,label="MITgcm Solution")
   #
   return df,pl
end
