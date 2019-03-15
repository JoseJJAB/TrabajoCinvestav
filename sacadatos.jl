

function sacainfo(entrada)
    entrada["description"][1].data
end

function devuelvedatos700B(h5datos, onchannel)
    #=
    Funcion que devuelve los trazos solamente
    como un dict
    Esta version de la funcion solo esta bien probada con Archivos Estilo AxonClamp700B
    =#
    a=()
    result=Dict{String,Any}()
    if exists(h5datos, onchannel)
        aux=read(datos[onchannel])
        for (keys, values) in aux
            #println(keys)
            if keys=="section_00"
                println("la descripcion de tus barridas de datos son las siguientes")
                println(values["description"])
                a=sacainfo(values)
            end
            if keys != "description"
                result[keys]=values["data"]
            end
        end
        else
        println("no encontre el grupo que pediste")
        
    end
    return (a,result)
end




function devuelvedatos2B(h5datos)
    #=
    Funcion que devuelve los trazos solamente
    como un dict
    Esta version la usaremos para archivos 2B
    =#
    nombresecreto=read(datos["channels"]["ch0"])[1]
    a=()
    result=Dict{String,Any}()
    
    if exists(h5datos, nombresecreto)
        
        aux=read(datos[nombresecreto])
        for (keys, values) in aux
            #println(keys)
            if (keys=="section_00") | (keys=="section_000") 
                println("la descripcion de tus barridas de datos son las siguientes")
                println(values["description"])
                a=sacainfo(values)
            end
            if keys != "description"
                result[keys]=values["data"]
            end
        end
        else
        println("no encontre el grupo que pediste")
  
    end
    
    return (a,result)
end


        

