=info
    生成能够精确覆盖的矩阵_随机填充法.pl
=cut
package RandMatrix;
use List::Util qw/shuffle sum/;

our $n = 8;    #有效行
our $m = 30;   #列

sub fill_rand_row
{
    my ($mat, $insert) = @_;
    for my $iter ( 1.. $insert )
    {
        my $row = rand( 5 );  #控制在前5行
        splice @$mat, $row, 0, [map { int(rand(2)) } (1..$m) ];
    }
}

sub create_mat
{
    my $mat = shift;
    $$mat = [ map { [map { "0" } (1 .. $m)] } (1 .. $n) ];
    my @rands = shuffle ( 0 .. $m-1 );

    # 优先在每一行随机填入一个位，确保不会出现全0的情况
    grep {  $$mat->[ $_ ][shift @rands] = 1   } ( 0 .. $n-1 );
    # 随机填入
    grep { $$mat->[int(rand $n)][shift @rands] = 1 } ( 1 .. $m-$n );
}

sub dump_mat
{
    my $ref = shift;
    for my $r ( 0 .. $#$ref )
    {
        printf "%s, => %d\n", join(",", @{$ref->[$r]} ), sum( @{$ref->[$r]} ) ;
    }
}

1;