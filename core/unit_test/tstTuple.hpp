/****************************************************************************
 * Copyright (c) 2018 by the Cabana authors                                 *
 * All rights reserved.                                                     *
 *                                                                          *
 * This file is part of the Cabana library. Cabana is distributed under a   *
 * BSD 3-clause license. For the licensing terms see the LICENSE file in    *
 * the top-level directory.                                                 *
 *                                                                          *
 * SPDX-License-Identifier: BSD-3-Clause                                    *
 ****************************************************************************/

#include <Cabana_Tuple.hpp>
#include <Cabana_Parallel.hpp>

#include <Kokkos_Core.hpp>

#include <gtest/gtest.h>

namespace Test
{

//---------------------------------------------------------------------------//
// Check the data given a set of values.
template<class view_type>
void checkDataMembers(
    view_type view,
    const float fval, const double dval, const int ival,
    const std::size_t dim_1, const std::size_t dim_2, const std::size_t dim_3 )
{
    for ( std::size_t idx = 0; idx < view.extent(0); ++idx )
    {
        // Member 0.
        for ( std::size_t i = 0; i < dim_1; ++i )
            for ( std::size_t j = 0; j < dim_2; ++j )
                for ( std::size_t k = 0; k < dim_3; ++k )
                    EXPECT_EQ( view(idx).template get<0>( i, j, k ),
                               fval * (i+j+k) );

        // Member 1.
        EXPECT_EQ( view(idx).template get<1>(), ival );

        // Member 2.
        for ( std::size_t i = 0; i < dim_1; ++i )
            EXPECT_EQ( view(idx).template get<2>( i ), dval * i );

        // Member 3.
        for ( std::size_t i = 0; i < dim_1; ++i )
            for ( std::size_t j = 0; j < dim_2; ++j )
                EXPECT_EQ( view(idx).template get<3>( i, j ), dval * (i+j) );
    }
}

//---------------------------------------------------------------------------//
// Tuple test
void runTest()
{
    // Data dimensions.
    const std::size_t dim_1 = 3;
    const std::size_t dim_2 = 2;
    const std::size_t dim_3 = 4;

    // Declare member types.
    using T0 = float[dim_1][dim_2][dim_3];
    using T1 = int;
    using T2 = double[dim_1];
    using T3 = double[dim_1][dim_2];

    // Declare data types.
    using DataTypes = Cabana::MemberTypes<T0,T1,T2,T3>;

    // Declare the tuple type.
    using Tuple_t = Cabana::Tuple<DataTypes>;

    // Create a view of tuples.
    using memory_space = TEST_MEMSPACE;
    std::size_t num_data = 453;
    Kokkos::View<Tuple_t*,typename memory_space::kokkos_memory_space>
        tuples( "tuples", num_data );

    // Initialize data.
    float fval = 3.4;
    double dval = 1.23;
    int ival = 1;
    auto init_func = KOKKOS_LAMBDA( const std::size_t idx )
    {
        // Member 0.
        for ( std::size_t i = 0; i < dim_1; ++i )
            for ( std::size_t j = 0; j < dim_2; ++j )
                for ( std::size_t k = 0; k < dim_3; ++k )
                    tuples( idx ).get<0>( i, j, k ) = fval * (i+j+k);

        // Member 1.
        tuples( idx ).get<1>() = ival;

        // Member 2.
        for ( std::size_t i = 0; i < dim_1; ++i )
            tuples( idx ).get<2>( i ) = dval * i;

        // Member 3.
        for ( std::size_t i = 0; i < dim_1; ++i )
            for ( std::size_t j = 0; j < dim_2; ++j )
                tuples( idx ).get<3>( i, j ) = dval * (i+j);
    };
    Kokkos::fence();

    Kokkos::RangePolicy<TEST_EXECSPACE> policy( 0, num_data );

    Kokkos::parallel_for( policy, init_func );
    Kokkos::fence();

    // Check data members of the for proper initialization.
    checkDataMembers( tuples, fval, dval, ival, dim_1, dim_2, dim_3 );
}

//---------------------------------------------------------------------------//
// RUN TESTS
//---------------------------------------------------------------------------//
TEST_F( TEST_CATEGORY, tuple_test )
{
    runTest();
}

//---------------------------------------------------------------------------//

} // end namespace Test
