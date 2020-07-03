workflow SimpleVariantDiscovery {
  File strling
  File ref_fasta
  File ref_str
  File bam
  File bam_index
  String sample

  call str_extract {
    input:
      strling = strling,
      ref_fasta = ref_fasta,
      ref_str = ref_str,
      bam = bam,
      bam_index = bam_index,
      sample = sample
  }
   call str_call_individual {
    input:
      strling = strling,
      ref_fasta = ref_fasta,
      ref_str = ref_str,
      bam = bam,
      bam_index = bam_index,
      sample = sample,
      bin = str_extract.bin
  }

}

task str_extract {
  File strling
  File ref_fasta
  File ref_str
  String sample
  File bam
  File bam_index

  command {
    ${strling} extract \
      -f ${ref_fasta} \
      -g ${ref_str} \
      ${bam} \
      ${sample}.bin
  }
  output {
    File bin = "${sample}.bin"
  }
}

task str_call_individual {
  File strling
  File ref_fasta
  File ref_str
  String sample
  File bam
  File bam_index
  File bin

  command {
    ${strling} extract \
      -f ${ref_fasta} \
      -g ${ref_str} \
      ${bam} \
      ${sample}.bin

    ${strling} call \
      -f ${ref_fasta} \
      -o ${sample} \
      ${bam} \
      ${bin}
  }
  output {
    File output_bounds = "${sample}-bounds.txt"
    File output_unplaced = "${sample}-unplaced.txt"
    File output_genotype = "${sample}-genotype.txt"
  }
}

