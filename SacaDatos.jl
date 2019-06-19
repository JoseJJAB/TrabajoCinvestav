module SacaDatos

using HDF5

export sacainfo, devuelvedatos

function sacainfo(entrada)
    entrada["description"][1].data
end

function devuelvedatos(h5datos, onchannel)
    #=
    Funcion que devuelve los trazos solamente
    como un dict
    =#
    a=()
    result=Dict{String,Any}()
    if exists(h5datos, onchannel)
        aux=read(h5datos[onchannel])
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


end #module
