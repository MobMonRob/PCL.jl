import Base: call, filter

abstract AbstractFilter

@inline handle(f::AbstractFilter) = f.handle

setInputCloud(f::AbstractFilter, cloud::PointCloud) =
    @cxx cxxpointer(handle(f))->setInputCloud(handle(cloud))
filter(f::AbstractFilter, cloud::PointCloud) =
    @cxx cxxpointer(handle(f))->filter(cxxderef(handle(cloud)))

type UniformSampling{T} <: AbstractFilter
    handle::SharedPtr
end

function call{T}(::Type{UniformSampling{T}})
    handle = @sharedptr "pcl::UniformSampling<\$T>"
    UniformSampling{T}(handle)
end

setRadiusSearch(us::UniformSampling, ss) =
    @cxx cxxpointer(handle(us))->setRadiusSearch(ss)

type PassThrough{T} <: AbstractFilter
    handle::SharedPtr
end

function call{T}(::Type{PassThrough{T}})
    handle = @sharedptr "pcl::PassThrough<\$T>"
    PassThrough{T}(handle)
end

setFilterFieldName(pass::PassThrough, name::AbstractString) =
    @cxx cxxpointer(handle(pass))->setFilterFieldName(pointer(name))
setFilterLimits(pass::PassThrough, lo, hi) =
    @cxx cxxpointer(handle(pass))->setFilterLimits(lo, hi)
setFilterLimitsNegative(pass::PassThrough, v::Bool) =
    @cxx cxxpointer(handle(pass))->setFilterLimitsNegative(v)

type VoxelGrid{T} <: AbstractFilter
    handle::SharedPtr
end

call{T}(::Type{VoxelGrid{T}}) = VoxelGrid{T}(@sharedptr "pcl::VoxelGrid<\$T>")
setLeafSize(v::VoxelGrid, lx, ly, lz) =
    @cxx cxxpointer(handle(v))->setLeafSize(lx, ly, lz)

type StatisticalOutlierRemoval{T} <: AbstractFilter
    handle::SharedPtr
end

function call{T}(::Type{StatisticalOutlierRemoval{T}})
    StatisticalOutlierRemoval{T}(
        @sharedptr "pcl::StatisticalOutlierRemoval<\$T>")
end

for f in [:setMeanK, :setStddevMulThresh]
    @eval begin
        $f(s::StatisticalOutlierRemoval, v) = @cxx cxxpointer(handle(s))->$f(v)
    end
end
