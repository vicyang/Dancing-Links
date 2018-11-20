package ImagerFont;


use utf8;
use Encode;
use Imager;
use Encode;
use OpenGL;

our $SIZE = 30;
our $font = Imager::Font->new(file  => encode('gbk', 'C:/windows/fonts/arialbd.ttf'), #STXINGKA.TTF
                              size  => $SIZE );
our $bbox = $font->bounding_box(string=>"");

sub get_text_map
{
    our ($font, $SIZE);
    my ( $char, $ref ) = @_;

    my $bbox = $font->bounding_box( string => $char );
    my $img = Imager->new(xsize=>$bbox->display_width, 
                          ysize=>$bbox->text_height, channels=>4);

    my $h = $img->getheight();
    my $w = $img->getwidth();

    # # 填充画布背景色
    # $img->box(xmin => 0, ymin => 0, xmax => $w, ymax => $h,
    #         filled => 1, color => '#336699');

    $img->align_string(
               font  => $font,
               text  => $char,
               x     => 0,
               y     => $h,
               size  => $SIZE,
               color => 'white',
               aa    => 1,     # anti-alias
               valign => 'bottom',
            );

    $ref->{h} = $h, $ref->{w} = $w;

    my @rasters;
    my @colors;
    for my $y ( reverse 0 .. $h - 1 )
    {
        @colors = $img->getpixel( x => [ 0 .. $w - 1 ], y => [$y] );
        grep { push @rasters, $_->rgba  } @colors;
    }

    $ref->{array} = OpenGL::Array->new( scalar( @rasters ), GL_UNSIGNED_BYTE ); 
    $ref->{array}->assign(0, @rasters);
}

1;