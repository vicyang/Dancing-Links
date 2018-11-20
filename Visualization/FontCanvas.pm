package FontCanvas;

use strict;
use OpenGL;
use Imager;
use threads::shared;

our $SIZE = 20;
our $font;
our $bbox;
our $img :shared;
our $ybase = 0.0;
our $h;
our $w;

sub init
{
    our ($SIZE, $font, $bbox, $img);
    my ($canvas) = @_;

    $font = Imager::Font->new(file  => 'C:/windows/fonts/Consola.ttf', #STXINGKA.TTF
                              size  => $SIZE );
    $bbox = $font->bounding_box( string => "a" );
    $img = shared_clone(Imager->new(xsize=>400, ysize=>400, channels=>4));
    $ybase = 0.0;

    $h = $img->getheight();
    $w = $img->getwidth();

    # 填充画布背景色
    $img->box(xmin => 0, ymin => 0, xmax => $w, ymax => $h,
            filled => 1, color => '#336699');

    my @rasters;
    my @colors;
    for my $y ( reverse 0 .. $h - 1 )
    {
        @colors = $img->getscanline( y => $y );
        grep { push @rasters, $_->rgba  } @colors;
    }

    $canvas->{w} = $w;
    $canvas->{h} = $h;
    $canvas->{rasters} = shared_clone( \@rasters );
    printf "init %s\n", $img;
}

sub update_text
{
    our ($font, $SIZE, $img, $ybase, $bbox);
    our ($h, $w);
    my ( $string, $canvas ) = @_;

    $ybase += $bbox->font_height;

    $img->string(
               font  => $font,
               text  => $string,
               x     => 0,
               y     => $ybase,
               size  => $SIZE,
               color => 'gold',
               aa    => 1,     # anti-alias
            );

    printf "update %s\n", $img;
    
    my @rasters;
    my @colors;
    for my $y ( reverse 0 .. $h - 1 )
    {
        @colors = $img->getscanline( y => $y );
        grep { push @rasters, $_->rgba  } @colors;
    }

    $canvas->{rasters} = shared_clone( \@rasters );
    printf "update: %d %d %d\n", $#{$canvas->{rasters}}, $#rasters, $#colors;
}

1;