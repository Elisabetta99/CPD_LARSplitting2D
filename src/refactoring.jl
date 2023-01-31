using LinearAlgebraicRepresentation
Lar = LinearAlgebraicRepresentation
using IntervalTrees
using SparseArrays
using NearestNeighbors
using BenchmarkTools
using OrderedCollections
using Base.Threads



#---------------------------------------------------------------------
#	2D containment test
#---------------------------------------------------------------------

"""
Half-line crossing test. Utility function for `pointInPolygonClassification` function.
Update the `count` depending of the actual crossing of the tile half-line.
"""
function crossingTest(new::Int, old::Int, count::T, status::Int)::Number where T <: Real
    if status == 0
        status = new
        count += 0.5
    else
        if status == old
        	count += 0.5
        else
        	count -= 0.5
        end
        status = 0
    end
end



"""
	setTile(box)(point)

Set the `tileCode` of the 2D bbox `[b1,b2,b3,b4]:=[ymax,ymin,xmax,xmin]:= x,x,y,y`
including the 2D `point` of `x,y` coordinates.
Depending on `point` position, `tileCode` ranges in `0:15`, and uses bit operators.
Used to set the plane tiling depending on position of the query point,
in order to subsequently test the tile codes of edges of a 2D polygon, and determine
if the query point is either internal, external, or on the boundary of the polygon.
Function to be parallelized ...

```julia
c1,c2 = tilecode(p1),tilecode(p2)
c_edge, c_un, c_int = c1 ⊻ c2, c1 | c2, c1 & c2
```
"""

function setTile(box)
	tiles = [[9,1,5],[8,0,4],[10,2,6]]
	b1,b2,b3,b4 = box
	function tileCode(point)
		x,y = point
		code = 0
		if y>b1 code=code|1 end
		if y<b2 code=code|2 end
		if x>b3 code=code|4 end
		if x<b4 code=code|8 end
		return code
	end
	return tileCode
end



"""
	pointInPolygonClassification(V,EV)(pnt)

Point in polygon classification.

# Example

```julia
result = []
classify = pointInPolygonClassification(V,EV)
```
"""
function edgecode1(c_int) #c_edge == 1
    if c_int == 0 return "p_on"
    elseif c_int == 4 crossingTest(1,2,status, counter) end 
end 

function edgecode2(c_int) #c_edge == 2
    if c_int == 0 return "p_on"
    elseif c_int == 4 crossingTest(2,1,status, counter) end 
end 

function edgecode3(c_int) #c_edge == 3
    if c_int == 0 return "p_on"
    elseif c_int == 4 counter += 1 end 
end 

function edgecode4(c_un) #c_edge == 4
    if c_un == 4 return "p_on" end 
end 

function edgecode5(c1,c2) #c_edge == 5
    if (c1==0) | (c2==0) return "p_on"
    else crossingTest(1,2,status, counter) end 
end 

function edgecode6(c1,c2) #c_edge == 6
    if ((c1==0) | (c2==0)) return "p_on"
    else crossingTest(2,1,status, counter) end 
end 

function edgecode7(counter) #c_edge == 7
    counter += 1
end 

function edgecode8(c_un) #c_edge == 8
    if (c_un == 8) return "p_on" end   
end

function edgecode9_10(c1,c2) #c_edge == 9/10
    if ((c1 ==0) | (c2==0)) return "p_on" end
end

function edgecode11() #c_edge == 11
    count = count
end

function edgecode12(c_un) #c_edge = 12
    if (c_un == 12 ) return "p_on" end    
end

function edgecode13(c1,c2) #c_edge = 13
    if (( c1 ==4) | (c2 == 4))
        crossingTest(1,2,status, counter) end
end

function edgecode14(c1,c2) #c_edge = 14
    if (( c1 ==4) | (c2 == 4))
        crossingTest(2,1,status, counter) end
end

function edgecode15(x1,x2,y1,y2,x,y)
    x_int = ((y-y2)*(x1-x2)/(y1-y2))+x2
    if x_int > x counter+=1
    elseif (x_int == x) return "p_on" end
end

function pointInPolygonClassification(V,EV) 
    function pointInPolygonClassification0(pnt)
        x,y = pnt
        xmin,xmax,ymin,ymax = x,x,y,y
        tilecode = setTile([ymax,ymin,xmax,xmin])
        count,status = 0,0

        for (k,edge) in enumerate(EV)
            p1,p2 = V[:,edge[1]],V[:,edge[2]]
            (x1,y1),(x2,y2) = p1,p2
            c1,c2 = tilecode(p1),tilecode(p2)
            c_edge, c_un, c_int = c1⊻c2, c1|c2, c1&c2

            if (c_edge == 0) edgecode1(c_un)
            elseif (c_edge == 12) edgecode12(c_un)
            elseif (c_edge == 3) edgecode3(c_int)
            elseif (c_edge == 15) edgecode15(x1,x2,y1,y2,x,y)
            elseif (c_edge == 13) edgecode13(c1,c2)
            elseif (c_edge == 14) edgecode14(c1,c2)
            elseif (c_edge == 7) edgecode7(counter)
            elseif (c_edge == 11) edgecode11()
            elseif (c_edge == 1) edgecode1(c_int)
            elseif (c_edge == 2) edgecode2(c_int)
            elseif (c_edge == 4) edgecode4(c_un)
            elseif (c_edge == 8) edgecode8(c_un)
            elseif (c_edge == 5) edgecode5(c1,c2)
            elseif (c_edge == 6) edgecode6(c1,c2)
            elseif ((c_edge == 9) | (c_edge == 10)) edgecode9_10(c1,c2)
            end
        end
        if (round(count)%2)==1
        	return "p_in"
        else
        	return "p_out"
        end
    end
    return pointInPolygonClassification0
end



#---------------------------------------------------------------------
#	Refactoring pipeline
#---------------------------------------------------------------------

"""
	input_collection(data::Array)::Tuple

*Facet selection*. Construction of a ``(d-1)``-dimensional collection from a ``(d-1)``-
or ``d``-dimensional one. ``0-chain`` of `LAR` type are used as *input*.

*Output* is ``admissible input`` for algorithms of the *2D/3D arrangement* pipeline.

# Example 2D

An assembly of geometric objects is generated, and their assembly, including rotated
and translated chains, is built producing a collection of input LAR models.

```julia
V,(_,EV,FV) = Lar.cuboidGrid([4,4],true);
W,(_,EW,FW) = Lar.cuboidGrid([3,5],true);
mycircle(r,n) = Lar.circle(r)(n)

data2d1 = (V,EV)
data2d2 = Lar.Struct([ Lar.t(2,2), Lar.r(pi/3), Lar.t(-1.5,-2.5), (W,EW) ])
data2d3 = Lar.Struct([ Lar.t(2,2), mycircle(2.5,16) ])
data2d4 = Lar.Struct([ Lar.t(3.5,3.5), mycircle(.25,16) ])
data2d5 = Lar.Struct([ Lar.t(5,3.5), mycircle(.5,16) ])
data2d6 = Lar.Struct([ Lar.t(5,3.5), mycircle(.25,16) ])

model2d = input_collection( [ data2d1, data2d2, data2d3, data2d4, data2d5, data2d6 ] )
V,EV = model2d
VV = [[k] for k in 1:size(V,2)];
using Plasm
Plasm.view( Plasm.numbering(.5)((V,[VV,EV])) )
```
Note that `V,EV` is not a cellular complex, since 1-cells intersect out of 0-cells.

# Example 3D

```julia
V,FV = Lar.sphere(2)([3,4])
EV = Lar.simplexFacets(FV)
mysphere = V,FV,EV

data3d1 = mysphere
data3d2 = Lar.Struct([ Lar.t(0,1,0), mysphere ])
data3d3 = Lar.Struct([ Lar.t(0,0.5,0), Lar.s(0.4,0.4,0.4), mysphere ])
data3d4 = Lar.Struct([ Lar.t(4,0,0), Lar.s(0.8,0.8,0.8), mysphere ])
data3d5 = Lar.Struct([ Lar.t(4,0,0), Lar.s(0.4,0.4,0.4), mysphere ])

model3d = input_collection([ data3d1, data3d2, data3d3, data3d4, data3d5 ])
V,FV,EV = model3d
VV = [[k] for k in 1:size(V,2)];
using Plasm
Plasm.view( Plasm.numbering(1)((V,[VV, EV])) )
```

Note that `V,FV,EV` is not a cellular complex, since 1-cells and
2-cells intersect out of 0-cells.

"""
function input_collection(data::Array)::Lar.LAR
	assembly = Lar.Struct(data)
	return Lar.struct2lar(assembly)
end

function boundingbox(vertices::Lar.Points)
    firstDim = vertices[1,:]
    secondDim = vertices[2,:]
    if (size(vertices,1)==3)
        thirdDim = vertices[3,:]
         minimum = Threads.@spawn hcat([min(firstDim...), min(secondDim...), min(thirdDim...)])
         maximum = Threads.@spawn hcat([max(firstDim...), max(secondDim...), max(thirdDim...)])
    else
         minimum = Threads.@spawn hcat([min(firstDim...), min(secondDim...)])
         maximum = Threads.@spawn hcat([max(firstDim...), max(secondDim...)])
    end
    return fetch(minimum),fetch(maximum)
 end

function coordintervals(coord,bboxes)
	boxdict = OrderedDict{Array{Float64,1},Array{Int64,1}}()
	for (h,box) in enumerate(bboxes)
		key = box[coord,:]
		if haskey(boxdict,key) == false
			boxdict[key] = [h]
		else
			push!(boxdict[key], h)
		end
	end
	return boxdict
end

function boxcovering(bboxes, index, tree)
    covers = [[zero(eltype(Int64))] for k=1:length(bboxes)]		#zero(eltype(Int64)) serve per rendere covers type stable
    @threads for (i,boundingbox) in collect(enumerate(bboxes))
        extent = bboxes[i][index,:]
        iterator = IntervalTrees.intersect(tree, tuple(extent...))
        addIntersection(covers, i, iterator)
    end
    return covers
end


"""
	spaceindex(model::Lar.LAR)::Array{Array{Int,1},1}

Generation of *space indexes* for all ``(d-1)``-dim cell members of `model`.

*Spatial index* made by ``d`` *interval-trees* on
bounding boxes of ``sigma in S_{d−1}``. Spatial queries solved by
intersection of ``d`` queries on IntervalTrees generated by
bounding-boxes of geometric objects (LAR cells).

The return value is an array of arrays of `int`s, indexing cells whose
containment boxes are intersecting the containment box of the first cell.
According to Hoffmann, Hopcroft, and Karasick (1989) the worst-case complexity of
Boolean ops on such complexes equates the total sum of such numbers.

# Examples 2D

```
julia> V = hcat([[0.,0],[1,0],[1,1],[0,1],[2,1]]...);

julia> EV = [[1,2],[2,3],[3,4],[4,1],[1,5]];

julia> Sigma = Lar.spaceindex((V,EV))
5-element Array{Array{Int64,1},1}:
 [4, 5, 2]
 [1, 3, 5]
 [4, 5, 2]
 [1, 3, 5]
 [4, 1, 3, 2]
```

From `model2d` value, available in `?input_collection` docstring:

```julia
julia> Sigma =  spaceindex(model2d);
```

# Example 3D

```julia
model = model3d
Sigma =  spaceindex(model3d);
Sigma
```
"""
function spaceindex(model::Lar.LAR)::Array{Array{Int,1},1}
	V,CV = model[1:2]
    dim = size(V,1)
    
    cellpoints = [ V[:,CV[k]]::Lar.Points for k=1:length(CV) ]		 # calcola le celle
    bboxes = [hcat(boundingbox2(cell)...) for cell in cellpoints]    # calcola i boundingbox delle celle
    
    xboxdict = Threads.@spawn coordintervals(1,bboxes)
    yboxdict = Threads.@spawn coordintervals(2,bboxes)

    # xs,ys sono di tipo IntervalTree
    xs = Threads.@spawn createIntervalTree(fetch(xboxdict))
    ys = Threads.@spawn createIntervalTree(fetch(yboxdict))
    
    xcovers = Threads.@spawn boxcovering2(bboxes, 1, fetch(xs))                       # lista delle intersezioni dei bb sulla coordinata x
    ycovers = Threads.@spawn boxcovering2(bboxes, 2, fetch(ys))                       # lista delle intersezioni dei bb sulla coordinata x
    covers = [intersect(pair...) for pair in zip(fetch(xcovers),fetch(ycovers))]      # lista delle intersezioni dei bb su entrambe le coordinate

    if dim == 3
        zboxdict = Threads.@spawn coordintervals(3,bboxes)
        zs = Threads.@spawn createIntervalTree(fetch(zboxdict))
        zcovers = Threads.@spawn boxcovering2(bboxes, 3, fetch(zs))
        covers = [intersect(pair...) for pair in zip(fetch(zcovers),covers)]
    end
    
    removeIntersection(covers)  #rimozione delle intersezioni con se stesso
    return covers
end




"""
	intersection(line1,line2)

Intersect two line segments in 2D, by computing the two line parameters of the intersection point.

The line segments intersect if both return parameters `α,β` are contained in the interval `[0,1]`.

# Example

```
julia> line1 = [[0.,0], [1,2]]
2-element Array{Array{Float64,1},1}:
 [0.0, 0.0]
 [1.0, 2.0]

julia> line2 = [[2.,0], [0,3]]
2-element Array{Array{Float64,1},1}:
 [2.0, 0.0]
 [0.0, 3.0]

julia> Lar.intersection(line1,line2)
(0.8571428571428571, 0.5714285714285714)
```
"""
function intersection(line1,line2)
	x1,y1,x2,y2 = vcat(line1...)
	x3,y3,x4,y4 = vcat(line2...)

	# intersect lines e1,e2
	det = (x4-x3)*(y1-y2)-(x1-x2)*(y4-y3)
	if det != 0.0
		a = 1/det
		b = [y1-y2 x2-x1; y3-y4 x4-x3]
		c = [x1-x3; y1-y3]
		(β,α) = a * b * c
	else
		if (y1==y2) == (y3==y4) || (x1==x2) == (x3==x4) # segments collinear
			 return nothing
		else
			 # segments parallel: no intersection
			 return nothing
		end
	end
	return α,β
end



"""
	linefragments(V,EV,Sigma)

Compute the sequences of ordered parameters fragmenting each input lines.

Extreme parameter values (`0.0` and `1.0`) are included in each output line.
`Sigma` is the spatial index providing the subset of lines whose containment boxes intersect the box of each input line (given by `EV`).

```
julia> V = hcat([[0.,0],[1,0],[1,1],[0,1],[2,1]]...);

julia> EV = [[1,2],[2,3],[3,4],[4,1],[1,5]];

julia> Sigma = Lar.spaceindex((V,EV))
5-element Array{Array{Int64,1},1}:
 [4, 5, 2]
 [1, 3, 5]
 [4, 5, 2]
 [1, 3, 5]
 [4, 1, 3, 2]

julia> Lar.linefragments(V,EV,Sigma)
5-element Array{Any,1}:
 [0.0, 1.0]
 [0.0, 0.5, 1.0]
 [0.0, 1.0]
 [0.0, 1.0]
 [0.0, 0.5, 1.0]
```
"""
function linefragments(V,EV,Sigma)
	# remove the double intersections by ordering Sigma
	m = length(Sigma)
	sigma = map(sort,Sigma)
	reducedsigma = sigma ##[filter(x->(x > k), sigma[k]) for k=1:m]
	# pairwise parametric intersection
	params = Array{Float64,1}[[] for i=1:m]
	@inbounds for h=1:m
		if sigma[h] ≠ []
			line1 = V[:,EV[h]]
			@inbounds for k in sigma[h]
				line2 = V[:,EV[k]]
				out = Lar.intersection(line1,line2) # TODO: w interval arithmetic
				if out ≠ nothing
					α,β = out
					if 0<=α<=1 && 0<=β<=1
						push!(params[h], α)
						push!(params[k], β)
					end
				end
			end
		end
	end
	# finalize parameters of fragmented lines
	fragparams = []
	for line in params
		push!(line, 0.0, 1.0)
		line = sort(collect(Set(line)))
		push!(fragparams, line)
	end
	return fragparams
end



"""
	fragmentlines(model::Lar.LAR)::Lar.LAR

Pairwise *intersection* of 2D *line segments*.

# Example 2D

```julia
V,EV = model2d
W, EW = Lar.fragmentlines(model2d) # OK
using Plasm
Plasm.viewexploded(W,EW)(1.2,1.2,1.2)
```
"""
function fragmentlines(model)
    V,EV = model
    Sigma = spaceindex(model)
    lineparams = linefragments(V,EV,Sigma)
    vertdict = OrderedDict{Array{Float64,1},Array{Int,1}}()
    pairs = collect(zip(lineparams, [V[:,e] for e in EV]))
    vertdict = OrderedDict{Array{Float64,1},Int}()
    W = Array[]
    EW = Array[]
    k = 0
    l = length(pairs)
    @inbounds for i = 1:l
        params = pairs[i][1]
        linepoints = pairs[i][2]
        v1 = linepoints[:,1]    # Isolo primo punto dello spigolo
        v2 = linepoints[:,2]    # Isolo secondo punto dello spigolo
        points = [ v1 + t*(v2 - v1) for t in params] 
        vs = zeros(Int64,1,length(points))
        PRECISION = 8
        numpoint = length(points)
        @inbounds for h = 1:numpoint
            points[h] = map(approxVal(PRECISION), points[h])
            if !haskey(vertdict, points[h])
                k += 1  # Genero ID punto 
                vertdict[points[h]] = k     # Associo l'ID al punto
                push!(W, points[h])     # Effettua una push del punto(x,y) nell'array W
            end
            vs[h] = vertdict[points[h]] 
        end
        m = length(vs) - 1
        @inbounds for k=1:m
            push!(EW, [vs[k], vs[k+1]])
        end
    end
    W,EW = hcat(W...),convert(Array{Array{Int64,1},1},EW)
    V,EV = congruence((W,EW))
    return V,EV
end


function fraglines(sx::Float64=1.2,sy::Float64=1.2,sz::Float64=1.2)
	function fraglines0(model)
		V,EV = Lar.fragmentlines(model)

		W = zeros(Float64, size(V,1), 2*length(EV))
		EW = Array{Array{Int64,1},1}()
		for (k,(v1,v2)) in enumerate(EV)
			if size(V,1)==2
				x,y = (V[:,v1] + V[:,v2]) ./ 2
				scx,scy = x*sx, y*sy
				t = [scx-x, scy-y]
			elseif size(V,1)==3
				x,y,z = (V[:,v1] + V[:,v2]) ./ 2
				scx,scy,scz = x*sx, y*sy, z*sz
				t = [scx-x, scy-y, scz-z]
			end
			W[:,2*k-1] = V[:,v1] + t
			W[:,2*k] = V[:,v2] + t
			push!(EW, [2*k-1, 2*k])
		end
		return W,EW
	end
	return fraglines0
end



"""
	congruence(model::Lar.LAR)::Lar.LAR
Graded bases of equivalence classes Ck (Uk ), with Uk = Xk /Rk for 0 ≤ k ≤ 2.

# Example

```julia
julia>
```
"""
function congruence(model)
    W,EW = model
    n = size(W,2)
    balltree = NearestNeighbors.BallTree(W)
    r = 0.0000000001
    near = Array{Any}(undef, n)
    @inbounds @threads for k=1:n
        near[k] = NearestNeighbors.inrange(balltree, W[:,k], r, true)
    end
    near = map(sort,near) 
    @inbounds @threads for k=1:n
        W[:,k] = W[:,near[k][1]]
    end
    pointidx = Array{Int64}(undef, n)
    @inbounds @threads for k=1:n
         pointidx[k] = near[k][1] 
    end
    l = length(pointidx)
    invidx = OrderedDict(zip(1:l, pointidx))
    V = Array{Array{Float64,1}}(undef, l)
    @inbounds @threads for k=1:l
        V[k] = W[:,k] 
    end
    
    EV = []
    m = length(EW)
    @inbounds for i = 1:m
        newedge = [invidx[EW[i][1]],invidx[EW[i][2]]]
        if newedge[1] !== newedge[2]
            push!(EV,newedge)
        end
    end
    filter!(x ->  length(x)==2, EV)
    EV = convert(Lar.Cells, EV)
    return hcat(V...),EV
end


"""
Funzioni aggiuntive create:

createIntervalTree(boxdict::AbstractDict{Array{Float64,1},Array{Int64,1}})
Struttura dati che contiene intervalli e che consente di trovare in modo efficiente tutti 
gli intervalli che si sovrappongono a un determinato intervallo o punto.

addIntersection(covers::Array{Array{Int64,1},1}, i::Int64, iterator)
Aggiunge gli elementi di iterator nell'i-esimo array di covers.

removeIntersection(covers::Array{Array{Int64,1},1})
Elimina le intersezioni di ogni bounding box con loro stessi.
"""


function createIntervalTree(boxdict::AbstractDict{Array{Float64,1},Array{Int64,1}})
    tree = IntervalTrees.IntervalMap{Float64,Array}()
    for (key, boxset) in boxdict
        tree[tuple(key...)] = boxset
    end
    return tree
end

function addIntersection(covers::Array{Array{Int64,1},1}, i::Int64, iterator)
    splice!(covers[i],1)		#splice serve a togliere gli zeri iniziali all'interno di covers
    @threads for x in collect(iterator)
        append!(covers[i],x.value)
    end
end

function removeIntersection(covers::Array{Array{Int64,1},1})
	@threads for k=1:length(covers)
        covers[k] = setdiff(covers[k],[k])	#toglie le intersezioni con se stesso 
    end
end
