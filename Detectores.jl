module Detectores

# frecuencia por default para muchas tonterias.
deffreq=25.0

#=
Necesitamos un parametro adecuado para el suavizado Gaussiano
Asi como esta solo funciona con datos a 25 kHz.
=#

export iart, tari, derivadadt,
       suaveduro, gauss, pesosgauss, suavegauss, g0,
       intervalosP, averagedictdict, separamochas




##********Funciones Auxiliares**************



function iart(i::Int,f::Int; freq=deffreq) 
  #  """function que pasa de intervalos enteros a tiempo en ms"""
aux=i:f
    result=aux./freq
end

function tari(it,ft; freq=deffreq)
    # funtion que pasa de tiempo en ms a intervalos enteros de indices
    auxi=round(Int, it*freq)
    auxf=round(Int, ft*freq)
    result=auxi:auxf
end

function derivadadt(xx::Array; freq=deffreq)
    aux=diff(xx).*freq
    result=vcat(aux, aux[end])
end

function suaveduro(trazo::Array, nv=9)
# funcion que promedia cada punto sobre sus vecinos
    aux=trazo
    l=length(trazo)
    cabeza=repeat([trazo[1]],nv)
    cola=repeat([trazo[end]],nv)
    aux=vcat(cabeza,aux,cola)
    result=zeros(l)
    for j=1:l
        result[j]=mean(aux[j:j+nv*2])
    end
    return result 
end


gauss(x, sigma)=exp(-(x/sigma)^2/2)

function pesosgauss(desv::Real,n::Int)
# funcion que promedia cada punto sobre sus vecinos, pero con peso gaussiano
    g=zeros(2*n+1)
    for j=-n:n
        g[j+n+1]=gauss(j,desv)
    end
    return g
end
        
function suavegauss(trazo::Array, nv=10)
    # nv corresponde a la desviacion estandar
    aux=trazo
    pesos=pesosgauss(nv/2,nv)
    pesoT=sum(pesos)
    l=length(trazo)
    cabeza=repeat([trazo[1]],nv)
    cola=repeat([trazo[end]],nv)
    aux=vcat(cabeza,aux,cola)
    result=zeros(l)
    for j=1:l
        for k=0:2*nv
        result[j]+=aux[j+k]*pesos[k+1]
        end
    end
    result/=pesoT
    return result 
end

# funcion que mueve la funcion por un desplazamiento d1
g0(xs::Array ,d1=-71)= xs.-(xs[1]+d1) 







###***** Funciones de Detectores Propiamente hablando
#=
las funciones de deteccion son extremadamente sensibles
a sus parametros de entrada
=#



function intervalosP(dtrazo::Array; preG=100, postG=400,
                     uinf=0.06*deffreq, usup=0.5*deffreq)
    # recuerdese: dtrazo es la DERIVADA del trazo suavizado, no el trazo.
    #se recomienda usar una diferencia suavizada en dtrazo

    esunbrinco(x)=  x>uinf 
    escontiguo(x,y)=(y-x)==1

    result=Dict{Int, Any}()
    preresult=Dict{Int, Array}()
    
    #=
    Este primer loop encuentra los intervalos
    de INDICES contiguos que cumplen estar
    por encima del umbral
    =#
    r=findall(esunbrinco,dtrazo)
    
    if !(isempty(r))
        k=1
        preresult[1]=[]
        for j=1:length(r)-1   
            if escontiguo(r[j], r[j+1])
                push!(preresult[k], r[j+1])
            else
                k+=1
                preresult[k]=[]
            end
         end 
    
        n=length(keys(preresult))
        
    else 
        println("no hay naaaaaada en la seccion")
    end
    
    tamanointervalo=length(dtrazo)
   
    #=
    A partir del diccionario obtenido en el loop anterior:
    1) Buscamos el maximo
    2) Vemos si su valor esta debajo del segundo umbral
    3) si si, procedemos a localizar su posicion en la lista ORIGINAL de datos
    4) devolvemos una lista con todos los numeritos en ese rango de 200 antes a 800 despues
    =#
     n=length(keys(preresult))
    if n>0    
    for j in keys(preresult)
        aux=preresult[j]
        (a, lugarlista) =findmax(dtrazo[aux[1]:aux[end]])
          #  println(aux)
        if a<usup
            lugarreal=aux[lugarlista]
            ai=lugarreal-preG
            af=lugarreal+postG
            (ai<1) ? ai=1 : ai=ai
            (af>tamanointervalo) ? af=tamanointervalo : af=af
            (maximototal, b)=findmax(dtrazo[ai:af])  
            println("vamos bien, ", ai, " ", af, " ", maximototal)
         
            if maximototal<40
                result[j]=ai:af
            end
                
                end # Este cierra el a<thres2 .
        
    end
    
    else
       # println(" te dije que no hay naaaada")
    end
    
    return result
end

function averagedictdict(ints::Dict, data::Dict)
    #= Funcion que toma un diccionario
    de intervalos y otro de arrays de valores.
    Si todos los intervalos miden lo mismo
    promedia el valor de los valores...
    =#
    aux=0
    k=0
    for subs in keys(ints)
        for j in keys(ints[subs])
            rango=ints[subs][j]
            valor=data[subs][rango]
            aux=aux.+valor
            k+=1
        end
    end
    result=aux./k
end

function risetime(derivada::Array, thresmin=0.25)
    #= la funcion busca donde pasamos el umbral thresmin, 
     y a partir de ahi el primer indice donde los valores de "derivada" 
     se vuelven negativos =#
    pasaumbral(x)= x > thresmin
    esnegativa(x) = sign(x)==-1
    
    aux1=findfirst(pasaumbral, derivada)
    aux2=findfirst(esnegativa, derivada[aux1:end])
    aux2=aux2+aux1
    # nos devuelve ambos indices absolutos
    result=(aux1, aux2)

end

function separamochas(datos::Dict)
    #= Dado que nuestras funciones nos devuelven
    diccionarios de arrays o de rangos,
    puede darse el caso de que sean desiguales.
    Esta funcion quita los rangos o intervalos mochos.
    =#
    
    Limpias=Dict{String,Dict}()
    Mochas=Dict{String,Dict}()
    #preG y posG son la amplitud de busqueda en cuadros (frames)
    # previa al evento sospechoso y posterior al evento sospechoso
    longi=preG+posG+1
    
    for subs in keys(datos)
    for j in keys(datos[subs])
            
        Limpias[subs]=Dict{Int, Array}()
        Mochas[subs]=Dict{Int, Array}()    
            # Primero verificamos que la longitud sea la correcta
        if length(datos[subs][j])==longi
            Limpias[subs][j]=datos[subs][j]
        else
            Mochas[subs][j]=datos[subs][j]
        end
        # Despues le quitamos los intervalos vacios
        if isempty(Limpias[subs])
            delete!(Limpias, subs)
        end
        
        if isempty(Mochas[subs])
            delete!(Mochas, subs)
        end
       
    end
end

result=(Limpias, Mochas)
end


end #module
