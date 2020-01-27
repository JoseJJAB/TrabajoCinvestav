module Detectores

# frecuencia por default para muchas tonterias.
deffreq=25.0

#=
Necesitamos un parametro adecuado para el suavizado Gaussiano
Asi como esta solo funciona con datos a 25 kHz.
=#

export iart, tari, derivadadt,
       suaveduro, gauss, pesosgauss, suavegauss, g0,
       intervalosP, averagedictdict, separamochas, risetime,
       normCut




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
    # Da los pesos gaussianos con desviacion desv,
    # n cuadros atras
    # uno en medio y n cuadros enfrente.
    # las distancias estan en unidades de cuadros!
    g=zeros(2*n+1)
    for j=-n:n
        g[j+n+1]=gauss(j,desv)
    end
    return g
end
        
function suavegauss(trazo::Array, nv=10)
    #  nv corresponde a la desviacion estandar 
    # en pasos discretos
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

function suavegauss(trazo::Array; dt::Real, freq=deffreq)
    # dt esta en ms y freq en kHz
    # equivalente a s y Hz.
    nv=ceil(Int, dt*freq)
    result=suavegauss(trazo, nv)
    return result
end



# funcion que mueve la funcion para que su primer punto este en d1
g0(xs::Array ,d1=-71)= xs.-(xs[1]+d1) 


#000000000000000000000000000000000000000000000000000000000000000000000000+
# 00000000000000000000000000000000000000000000000000000000000000000000000

###***** Funciones de Detectores Propiamente hablando
#=
las funciones de deteccion son extremadamente sensibles
a sus parametros de entrada
=#



function intervalosP(dtrazo::Array; preG=100, postG=400,
                     uinf=2, usup=3.4)
    # recuerdese: dtrazo es la DERIVADA del trazo suavizado, no el trazo.
    #se recomienda usar una diferencia suavizada en dtrazo
    #=
    Criterios plausibles para las derivadas sospechosas de
    ser una espigulata son los siguientes:
    la derivada minima PROMEDIO es de 2 mV/ms
    la derivada maximo PROMEDIO es de 3.4 mV/ms
    
     ¡¡¡¡ Los valores ya estan en la derivada en mV/ms !!!!

    =#
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
        println("no hay naaaaaada en esa seccion")
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
            
            if aux!=[]
                (a, lugarlista) =findmax(dtrazo[aux[1]:aux[end]])
                println(a)
                if a<usup
                    lugarreal=aux[lugarlista]
                    ai=lugarreal-preG
                    af=lugarreal+postG
                    (ai<1) ? ai=1 : ai=ai
                    (af>tamanointervalo) ? af=tamanointervalo : af=af
                    (maximototal, b)=findmax(dtrazo[ai:af])  
         
        #puede haber OTRO maximo en el mismo intervalo si 
        # por ejemplo, la derivada cambia de ritmo pero se mantiene positiva

                    if maximototal<usup
                        println("vamos bien, ", ai, " ", af, " ", maximototal)
                        result[j]=ai:af
                    end
                  
                    
                  
                
                end # Este cierra el a<usup2 .

            end # cierra el aux!=0
        end # cierra j in keys
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

function separamochas(datos::Dict, preG, posG)
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


function normCut(datossuave, intervaloslimpios)
    #=
      Esta funtion toma la lista de intervalos putativos (sospechososo)
     y la lista del diccionario de los datos ya limpiados (sin mochos o vacios.
    y devuelve una lista de trazos posibles en un dicctionario equivalente a los
    limpios de forma que todos los trazos empiecen en el valor promedio
    inicial.
    =#
    
    a=averagedictdict(intervaloslimpios, datossuave) # de ahora en adelante asi se sacan promedios sobre intervalos!
    offset=a[1]
    result=Dict{String,Dict}()
    
   for subs in keys(intervaloslimpios)
    result[subs]=Dict{Int, Array}()
    for j in keys(intervaloslimpios[subs])
         arre=intervaloslimpios[subs][j]
        # es mejor dibujar con rangos que con listas de numeros
        rango=arre[1]:arre[end]
        #normCut[subs][j]=suaves[subs][rango].-(suaves[subs][rango][1]-a[1])
        result[subs][j]=g0(datossuave[subs][rango],a[1]) # g0 es la funcion que empareja el punto de inicio
   
    end
        
    end
    return result
end



end #module

