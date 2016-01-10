using PCL
using Cxx
using Base.Test

import PCL.pcl: @sharedptr, SharedPtr

milk_cartoon_path = joinpath(dirname(@__FILE__), "data",
    "milk_cartoon_all_small_clorox.pcd")
table_scene_lms400_path = joinpath(dirname(@__FILE__), "data",
    "table_scene_lms400.pcd")

@testset "@sharedptr" begin
    v = @sharedptr "std::vector<double>"
    @test icxx"$v->size();" == 0
    v = @sharedptr "std::vector<double>" "10"
    @test icxx"$v->size();" == 10
end

@testset "Point types" begin
    p = pcl.PointXYZ()
    @test icxx"$p.x;" == 0.0f0
    @test icxx"$p.y;" == 0.0f0
    @test icxx"$p.z;" == 0.0f0

    p = pcl.PointXYZI()
    @test icxx"$p.intensity;" == 0.0f0

    p = pcl.PointXYZRGBA()
    @test icxx"$p.r;" == 0.0f0
    @test icxx"$p.g;" == 0.0f0
    @test icxx"$p.b;" == 0.0f0
    @test icxx"$p.a;" == 0xff
end

@testset "PoindCloud" begin
    cloudxyz = pcl.PointCloud{pcl.PointXYZ}()
    @test (@cxx (cloudxyz.handle)->get()) != C_NULL
    cloudxyzi = pcl.PointCloud{pcl.PointXYZI}()
    @test (@cxx (cloudxyzi.handle)->get()) != C_NULL

    milk_cloud = pcl.PointCloud{pcl.PointXYZRGBA}(milk_cartoon_path)
    @test (@cxx (milk_cloud.handle)->get()) != C_NULL

    @test pcl.width(milk_cloud) == 640
    @test pcl.height(milk_cloud) == 480
    @test !pcl.is_dense(milk_cloud)

    points = pcl.points(milk_cloud)
    @test length(points) == 640 * 480
    @test isa(points, pcl.StdVector)
    @test isa(points[1], pcl.PointXYZRGBARef)
    @test isa(points[1], pcl.PointXYZRGBAValOrRef)
end

@testset "pcl::io" begin
    cloudxyz = pcl.PointCloud{pcl.PointXYZ}()
    @test pcl.loadPCDFile(milk_cartoon_path, cloudxyz) == 0
    cloud_xyzrgb = pcl.PointCloud{pcl.PointXYZRGB}()
    @test pcl.loadPCDFile(milk_cartoon_path, cloud_xyzrgb) == 0
end

@testset "pcl::filters" begin
    cloud = pcl.PointCloud{pcl.PointXYZ}(table_scene_lms400_path)
    cloud_filtered = pcl.PointCloud{pcl.PointXYZ}()

    uniform_sampling = pcl.UniformSampling{pcl.PointXYZ}()
    pcl.setInputCloud(uniform_sampling, cloud)
    pcl.setRadiusSearch(uniform_sampling, 0.01)
    pcl.filter(uniform_sampling, cloud_filtered)
    @test length(cloud_filtered) < length(cloud)

    for sor in [
        pcl.VoxelGrid{pcl.PointXYZ}(),
        pcl.ApproximateVoxelGrid{pcl.PointXYZ}()
        ]
        pcl.setInputCloud(sor, cloud)
        pcl.setLeafSize(sor, 0.01, 0.01, 0.01)
        pcl.filter(sor, cloud_filtered)
        @test length(cloud_filtered) < length(cloud)
    end

    sor = pcl.StatisticalOutlierRemoval{pcl.PointXYZ}()
    pcl.setInputCloud(sor, cloud)
    pcl.setMeanK(sor, 10)
    pcl.setStddevMulThresh(sor, 1.0)
    pcl.filter(sor, cloud_filtered)
    @test length(cloud_filtered) < length(cloud)
end

@testset "std::vector" begin
    @test length(pcl.StdVector{Float64}()) == 0
    for n in 0:10
        @test length(pcl.StdVector{Float64}(n)) == n
    end
end
