!**********************************************************************************************
!
! PBE finite volume discretisation for growth
!
!**********************************************************************************************



!**********************************************************************************************

subroutine growth_tvd(ni,index,growth_source)

!**********************************************************************************************
!
! Growth for finite volume method
! Size can be diameter, volume etc.
!
! Stelios Rigopoulos, Fabian Sewerin, Binxuan Sun
!
!**********************************************************************************************

use pbe_mod

implicit none

double precision, dimension(m), intent(in) :: ni
integer, intent(in)                        :: index
double precision, intent(out)              :: growth_source

double precision :: G_terml,G_termr,phi
double precision :: gnl,gnr           !< (G*N) at left surface and right surface
double precision :: nl                !< Number density in left cell
double precision :: nll               !< Number density in left-left cell
double precision :: nc                !< Number density in this cell
double precision :: nr                !< Number density in right cell
double precision :: nrr               !< Number density in right-right cell
double precision :: eps               !< Tolerance for upwind ratio
double precision :: rl,rr             !< r+ at left and right surface

parameter(eps = 1.D1*epsilon(1.D0))

!**********************************************************************************************

!Only growth to the right present at nucleation interval

if (growth_function==1) then

  !Size-independent growth
  g_termr = g_coeff1
  g_terml = g_coeff1

else if (growth_function==2) then

  !Power-law growth
  g_termr = g_coeff1*(v(index)**g_coeff2)
  g_terml = g_coeff1*(v(index-1)**g_coeff2)

end if

!----------------------------------------------------------------------------------------------
!TVD scheme ref: S.Qamar et al 2006: A comparative study of high resolution schemes for solving
!                population balances in crystallization
!----------------------------------------------------------------------------------------------

if (g_coeff1>0.D0) then

  ! growth rate is along positive direction
  if (index==1) then

    gnl = 0.0D0
    gnr = g_termr * 0.5 * (ni(1)+ni(2))

  else if (index==m) then

    rl = (ni(m) - ni(m-1) + eps) / (ni(m-1) - ni(m-2) + eps)
    phi = max(0.0d0, min(2.0d0 * rl, min((1.0d0 + 2.0d0 * rl) / 3.0d0, 2.0d0)))
    gnl = g_terml * (ni(m-1) + 0.5 * phi * (ni(m-1) - ni(m-2)))
    gnr = g_termr * (ni(m) + 0.5*(ni(m) - ni(m-1)))

  else

    ! Fluxes at cell right surface
    nl = ni(index-1)
    nc = ni(index)
    nr = ni(index+1)
    rr = (nr - nc + eps) / (nc - nl + eps)
    phi = max(0.0d0, min(2.0d0 * rr, min((1.0d0 + 2.0d0 * rr) / 3.0d0, 2.0d0)))
    gnr = g_termr * (nc + 0.5 * phi * (nc - nl))

    ! Fluxes at cell left surface
    if (index==2 ) then
      gnl = g_terml * 0.5 * (ni(1)+ni(2))
    else
      nl = ni(index-2)
      nc = ni(index-1)
      nr = ni(index)
      rl = (nr - nc + eps) / (nc - nl + eps)
      phi = max(0.0d0, min(2.0d0 * rl, min((1.0d0 + 2.0d0 * rl) / 3.0d0, 2.0d0)))
      gnl = g_terml * (nc + 0.5 * phi * (nc - nl))
    end if
  end if

else

  ! growth rate is along negative direction
  if (index==1) then

    gnl = g_terml * (ni(1) + 0.5 * (ni(1) - ni(2)))
    rr = (ni(1) - ni(2) + eps) / (ni(2) - ni(3) + eps)
    phi = max(0.0d0, min(2.0d0 * rr, min((1.0d0 + 2.0d0 * rr) / 3.0d0, 2.0d0)))
    gnr = g_termr * (ni(2) + 0.5 * phi * (ni(2) - ni(3)))

  else if (index==m) then

    gnr = 0
    gnl = g_terml * 0.5 * (ni(m)+ni(m-1))

  else

    ! Fluxes at cell right surface
    if (index==m-1) then
      gnr = g_termr * 0.5 * (ni(m)+ni(m-1))
    else
      nl = ni(index)
      nc = ni(index+1)
      nr = ni(index+2)
      rr = (nl - nc + eps) / (nc - nr + eps)
      phi = max(0.0d0, min(2.0d0 * rr, min((1.0d0 + 2.0d0 * rr) / 3.0d0, 2.0d0)))
      gnr = g_termr * (nc + 0.5 * phi * (nc - nr))
    end if

    ! Fluxes at cell left surface
    nl = ni(index-1)
    nc = ni(index)
    nr = ni(index+1)
    rl = (nl - nc + eps) / (nc - nr + eps)
    phi = max(0.0d0, min(2.0d0 * rl, min((1.0d0 + 2.0d0 * rl) / 3.0d0, 2.0d0)))
    gnl = g_terml * (nc + 0.5 * phi * (nc - nr))

  end if

end if

if (i_gm==1) then
  ! For mass-conservative growth scheme, apply it after the first interval
  if (index>1) then
    growth_source = (v(index-1)*gnl - v(index)*gnr) / (0.5*(v(index)**2-v(index-1)**2))
  else
    growth_source = (gnl - gnr) / dv(index)
  end if
else
  growth_source = (gnl - gnr) / dv(index)
end if

end subroutine growth_tvd

!**********************************************************************************************