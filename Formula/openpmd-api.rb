class OpenpmdApi < Formula
  desc "C++ & Python API for Scientific I/O with openPMD"
  homepage "https://openpmd-api.readthedocs.io"
  url "https://github.com/openPMD/openPMD-api/archive/0.9.0-alpha.tar.gz"
  sha256 "2fd84f276453122b89ce66d4467ec162669315be2c75ae45d2a514d7b96a3a42"
  head "https://github.com/openPMD/openPMD-api.git", :branch => "dev"

  depends_on "cmake" => :build
  # adios
  depends_on "adios2"
  depends_on "catch2"
  depends_on "hdf5"
  # mpark-variant
  depends_on "nlohmann-json"
  depends_on "numpy"
  depends_on "pybind11"
  depends_on "python"

  def install
    args = std_cmake_args + %W[
      -DopenPMD_USE_MPI=OFF
      -DopenPMD_USE_HDF5=ON
      -DopenPMD_USE_ADIOS1=OFF
      -DopenPMD_USE_ADIOS2=ON
      -DopenPMD_USE_PYTHON=ON
      -DopenPMD_USE_INTERNAL_PYBIND11=OFF
      -DopenPMD_USE_INTERNAL_CATCH=OFF
      -DPYTHON_EXECUTABLE:FILEPATH=#{Formula["python"].opt_bin}/python3
      -DBUILD_TESTING=OFF
      -DBUILD_EXAMPLES=OFF
    ]
    mkdir "build" do
      system "cmake", "..", *args
      system "make", "install"
    end
  end

  test do
    (testpath/"write.cpp").write <<~EOS
      #include <openPMD/openPMD.hpp>
      #include <memory>
      #include <numeric>
      #include <cstdlib>
      #include <string>

      using namespace openPMD;

      void write(size_t const size, std::string const backend)
      {
        std::vector<double> global_data(size*size);
        std::iota(global_data.begin(), global_data.end(), 0.);

        Series series = Series(
          std::string("3_write_serial.").append(backend),
          AccessType::CREATE
        );

        MeshRecordComponent rho =
          series
            .iterations[1]
            .meshes["rho"][MeshRecordComponent::SCALAR];

        Datatype datatype = determineDatatype(shareRaw(global_data));
        Extent extent = {size, size};
        Dataset dataset = Dataset(datatype, extent);

        rho.resetDataset(dataset);
        series.flush();

        Offset offset = {0, 0};
        rho.storeChunk(shareRaw(global_data), offset, extent);

        series.flush();
      }

      int main()
      {
        write(3, "h5");
        write(3, "json");
        return EXIT_SUCCESS;
      }
    EOS
    system ENV.cxx, "-std=c++11", "write.cpp", "-I#{opt_include}", "-lopenPMD"
    system "./a.out"

    (testpath/"example.py").write <<~EOS
      import openpmd_api
      print(openpmd_api.__version__)
      print(openpmd_api.variants)
    EOS
    system "#{Formula["python"].opt_bin}/python3", "example.py"
  end
end
